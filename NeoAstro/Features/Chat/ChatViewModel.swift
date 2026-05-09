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
        var isSystem: Bool { messageType.hasPrefix("SYSTEM_") }
    }

    // MARK: - State

    let astrologer: AstrologerAPI
    var messages: [ChatMessage] = []
    var draft: String = ""
    var isAstroTyping: Bool = false
    var errorMessage: String?
    var hasEndedChat: Bool = false

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
            let msg = ChatMessage(
                id: id,
                body: p.message ?? "",
                isFromUser: false,
                messageType: p.messageType ?? "TEXT",
                sentAt: p.createdAt.map { Date(timeIntervalSince1970: $0 > 1_000_000_000_000 ? $0 / 1000 : $0) } ?? .now,
                pending: false,
                failed: false,
                sequenceId: p.sequenceId,
                astroId: p.astroId
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
