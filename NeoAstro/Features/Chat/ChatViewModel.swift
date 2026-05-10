import SwiftUI
import Observation

@Observable
@MainActor
final class ChatViewModel {

    // MARK: - Public types

    struct ChatMessage: Identifiable, Hashable {
        let id: String
        let body: String
        let isFromUser: Bool
        let messageType: String
        let sentAt: Date
        var pending: Bool = false
        var failed: Bool = false
        var sequenceId: Int? = nil
        var astroId: String? = nil
        var mediaURL: URL? = nil
        var audioDurationSeconds: Int? = nil
        var callSessionStatus: String? = nil   // ringing / ongoing / accepted / completed / ended / no_answer / rejected / missed
        var callFormFactor: String? = nil      // "voice" / "video"

        /// Wire types come in lowercase (`text`, `audio`, `image`, `voiceCall`)
        /// from the history endpoint and uppercase from realtime events.
        /// Normalize for the type accessors so both render the right bubble.
        private var normalizedType: String { messageType.uppercased() }

        var isSystem: Bool { normalizedType.hasPrefix("SYSTEM_") }
        var isText:  Bool { normalizedType == "TEXT" || normalizedType.isEmpty }
        var isAudio: Bool { normalizedType == "AUDIO" }
        var isImage: Bool { normalizedType == "IMAGE" }
        var isVoiceCall: Bool { normalizedType == "VOICECALL" }
    }

    // MARK: - State

    let astrologer: AstrologerAPI
    var messages: [ChatMessage] = []
    var draft: String = ""
    var isAstroTyping: Bool = false
    var errorMessage: String?
    var hasEndedChat: Bool = false
    var isUploadingMedia: Bool = false

    /// Highest astrologer-message sequenceId we've already reported as seen.
    /// Used to debounce `HUMAN_ANSWER_SEEN` so we only emit when the user
    /// genuinely scrolls into a new high-water-mark message.
    private var lastSeenSequenceId: Int = 0

    private weak var realtime: RealtimeStore?
    private var inboundDrainTask: Task<Void, Never>?
    private var typingDebounceTask: Task<Void, Never>?
    private var hasEmittedEnd = false

    // MARK: - Init

    init(astrologer: AstrologerAPI) {
        self.astrologer = astrologer
    }

    // MARK: - Wiring

    /// Called from `ChatView.onAppear`. Starts pulling inbound messages and
    /// driving the "astro typing" indicator from the realtime store.
    func wire(realtime: RealtimeStore) {
        self.realtime = realtime
        realtime.selectedAstroId = astrologer._id
        AppLog.info(.chat, "ChatViewModel wired astroId=\(astrologer._id)")
        startInboundDrain()
    }

    func unwire() {
        inboundDrainTask?.cancel()
        inboundDrainTask = nil
        typingDebounceTask?.cancel()
        typingDebounceTask = nil
        // Don't clear `selectedAstroId` here — the chat view may be hidden
        // briefly during navigation transitions; the store will be reset on
        // logout or when another feature view sets it.
    }

    // MARK: - Send

    func send() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let realtime, let chat = realtime.activeChat else {
            errorMessage = "Chat session not active"
            return
        }

        // Optimistic insert.
        let nextSeq = chat.sequenceCounter + 1
        if var active = realtime.activeChat {
            active.sequenceCounter = nextSeq
            realtime.activeChat = active
        }
        let localId = "local_\(UUID().uuidString)"
        let outgoing = ChatMessage(
            id: localId,
            body: trimmed,
            isFromUser: true,
            messageType: "TEXT",
            sentAt: .now,
            pending: true,
            sequenceId: nextSeq,
            astroId: chat.astroId
        )
        messages.append(outgoing)
        draft = ""

        let payload = RaiseQueryPayload(
            chatId: chat.chatId,
            astroId: chat.astroId,
            message: trimmed,
            messageType: "TEXT",
            sequenceId: nextSeq
        )

        Task {
            let ok = await NeoAstroSocket.shared.emitWithAck(.raiseQuery, payload: payload)
            await MainActor.run { [weak self] in
                guard let self else { return }
                if let idx = self.messages.firstIndex(where: { $0.id == localId }) {
                    var msg = self.messages[idx]
                    msg.pending = false
                    msg.failed = !ok
                    self.messages[idx] = msg
                }
                if !ok {
                    self.errorMessage = "Couldn't send. Tap to retry."
                    AppLog.warn(.chat, "RAISE_QUERY ack failed seq=\(nextSeq)")
                } else {
                    AppLog.debug(.chat, "RAISE_QUERY acked seq=\(nextSeq)")
                }
            }
        }
    }

    /// Send a captured voice note. Records to local file → upload to S3 via
    /// presigned URL → emit `RAISE_QUERY` with `messageType=AUDIO` and the
    /// public URL in `mediaUrls`.
    func sendVoiceNote(_ captured: CapturedAudio) {
        guard let realtime, let chat = realtime.activeChat else {
            errorMessage = "Chat session not active"
            return
        }

        let nextSeq = chat.sequenceCounter + 1
        if var active = realtime.activeChat {
            active.sequenceCounter = nextSeq
            realtime.activeChat = active
        }
        let localId = "local_\(UUID().uuidString)"
        let durationInt = Int(captured.duration.rounded())
        // Optimistic insert with the local file URL — once the upload finishes
        // we patch in the public URL so the in-flight bubble keeps playing.
        let outgoing = ChatMessage(
            id: localId,
            body: "Voice note",
            isFromUser: true,
            messageType: "AUDIO",
            sentAt: .now,
            pending: true,
            sequenceId: nextSeq,
            astroId: chat.astroId,
            mediaURL: captured.url,
            audioDurationSeconds: durationInt
        )
        messages.append(outgoing)

        Task {
            isUploadingMedia = true
            defer { isUploadingMedia = false }

            do {
                let publicURL = try await ChatMediaService.uploadVoiceNote(
                    data: captured.data,
                    chatId: chat.chatId,
                    astroId: chat.astroId
                )
                if let idx = messages.firstIndex(where: { $0.id == localId }) {
                    var msg = messages[idx]
                    msg.mediaURL = publicURL
                    messages[idx] = msg
                }
                let payload = RaiseQueryPayload(
                    chatId: chat.chatId,
                    astroId: chat.astroId,
                    message: "[voice]",
                    messageType: "AUDIO",
                    sequenceId: nextSeq,
                    mediaUrls: [publicURL.absoluteString],
                    audioDuration: durationInt
                )
                let ok = await NeoAstroSocket.shared.emitWithAck(.raiseQuery, payload: payload)
                markFinal(localId: localId, succeeded: ok)
            } catch {
                AppLog.error(.chat, "voice upload failed", error: error)
                markFinal(localId: localId, succeeded: false)
            }
        }
    }

    /// Send an image attachment. Same shape as voice: presigned upload then
    /// `RAISE_QUERY messageType=IMAGE`.
    func sendImage(_ data: Data) {
        guard let realtime, let chat = realtime.activeChat else {
            errorMessage = "Chat session not active"
            return
        }

        let nextSeq = chat.sequenceCounter + 1
        if var active = realtime.activeChat {
            active.sequenceCounter = nextSeq
            realtime.activeChat = active
        }
        let localId = "local_\(UUID().uuidString)"
        let outgoing = ChatMessage(
            id: localId,
            body: "Image",
            isFromUser: true,
            messageType: "IMAGE",
            sentAt: .now,
            pending: true,
            sequenceId: nextSeq,
            astroId: chat.astroId,
            mediaURL: nil
        )
        messages.append(outgoing)

        Task {
            isUploadingMedia = true
            defer { isUploadingMedia = false }
            do {
                let publicURL = try await ChatMediaService.uploadImage(
                    data: data,
                    chatId: chat.chatId,
                    astroId: chat.astroId
                )
                if let idx = messages.firstIndex(where: { $0.id == localId }) {
                    var msg = messages[idx]
                    msg.mediaURL = publicURL
                    messages[idx] = msg
                }
                let payload = RaiseQueryPayload(
                    chatId: chat.chatId,
                    astroId: chat.astroId,
                    message: "[image]",
                    messageType: "IMAGE",
                    sequenceId: nextSeq,
                    mediaUrls: [publicURL.absoluteString]
                )
                let ok = await NeoAstroSocket.shared.emitWithAck(.raiseQuery, payload: payload)
                markFinal(localId: localId, succeeded: ok)
            } catch {
                AppLog.error(.chat, "image upload failed", error: error)
                markFinal(localId: localId, succeeded: false)
            }
        }
    }

    private func markFinal(localId: String, succeeded: Bool) {
        guard let idx = messages.firstIndex(where: { $0.id == localId }) else { return }
        var msg = messages[idx]
        msg.pending = false
        msg.failed = !succeeded
        messages[idx] = msg
        if !succeeded {
            errorMessage = "Couldn't send. Tap to retry."
        }
    }

    /// Called from `ChatView` when an astrologer message scrolls into view.
    /// Emits `HUMAN_ANSWER_SEEN` only when the message advances the
    /// high-water mark — repeated visits to the same row are no-ops.
    func messageBecameVisible(_ message: ChatMessage) {
        guard !message.isFromUser, !message.isSystem else { return }
        guard let seq = message.sequenceId, seq > lastSeenSequenceId else { return }
        guard let realtime, let chat = realtime.activeChat else { return }
        lastSeenSequenceId = seq
        Task {
            await NeoAstroSocket.shared.emit(
                .humanAnswerSeen,
                payload: HumanAnswerSeenPayload(chatId: chat.chatId, sequenceId: seq)
            )
        }
    }

    /// User typed — debounce to a single USER_TYPING emit per ~1.5s window.
    func userTypingTouched() {
        guard let realtime, let chat = realtime.activeChat else { return }
        typingDebounceTask?.cancel()
        typingDebounceTask = Task { [weak self] in
            // Fire immediately at start of window, suppress for the rest.
            await NeoAstroSocket.shared.emit(
                .userTyping,
                payload: UserTypingPayload(astroId: chat.astroId, chatId: chat.chatId)
            )
            try? await Task.sleep(for: .seconds(1.5))
            self?.typingDebounceTask = nil
        }
    }

    func endChat() {
        guard !hasEmittedEnd, let realtime, let chat = realtime.activeChat else { return }
        hasEmittedEnd = true
        AppLog.info(.chat, "VM · endChat chatId=\(chat.chatId)")
        Task {
            await NeoAstroSocket.shared.emit(
                .endChat,
                payload: EndChatPayload(chatId: chat.chatId)
            )
        }
        hasEndedChat = true
    }

    // MARK: - Inbound drain

    private func startInboundDrain() {
        inboundDrainTask?.cancel()
        guard let realtime else { return }

        // Pull-loop: poll the realtime store's drain function on every event
        // tick. Polling here is cheap and avoids exposing a per-message
        // observer API on the store.
        inboundDrainTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let inbound = realtime.consumeInboundMessages()
                if !inbound.isEmpty {
                    self.appendInbound(inbound)
                }
                self.refreshTypingIndicator()
                if realtime.activeChat == nil && !self.hasEndedChat && !self.messages.isEmpty {
                    self.hasEndedChat = true
                }
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    private func appendInbound(_ payloads: [AnswerQueryPayload]) {
        for p in payloads {
            let id = p._id ?? "remote_\(UUID().uuidString)"
            // Idempotency: skip if we already have this id.
            if messages.contains(where: { $0.id == id }) { continue }
            let messageType = p.messageType ?? "TEXT"
            let mediaURL: URL? = {
                if messageType == "AUDIO", let s = p.audioUrl { return URL(string: s) }
                if messageType == "IMAGE", let s = p.mediaUrls?.first { return URL(string: s) }
                return p.mediaUrls?.first.flatMap(URL.init(string:))
            }()
            let msg = ChatMessage(
                id: id,
                body: p.message ?? "",
                isFromUser: false,
                messageType: messageType,
                sentAt: p.createdAt.map { Date(timeIntervalSince1970: $0 > 1_000_000_000_000 ? $0 / 1000 : $0) } ?? .now,
                pending: false,
                failed: false,
                sequenceId: p.sequenceId,
                astroId: p.astroId,
                mediaURL: mediaURL,
                audioDurationSeconds: p.audioDuration
            )
            messages.append(msg)
        }
    }

    private func refreshTypingIndicator() {
        guard let realtime else { isAstroTyping = false; return }
        if let until = realtime.astroTypingUntil, until > .now {
            isAstroTyping = true
        } else {
            isAstroTyping = false
        }
    }
}
