import SwiftUI

@Observable
@MainActor
final class ChatHistoryViewModel {
    let conversation: ConversationSummary
    var messages: [HistoricalMessage] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var astrologer: ConversationAstrologerLite?

    init(conversation: ConversationSummary) {
        self.conversation = conversation
    }

    func load() async {
        guard messages.isEmpty, let astroId = conversation.astroId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await ChatHistoryService.messages(with: astroId)
            messages = result.messages
            astrologer = result.astrologer
            AppLog.info(.chat, "VM · history loaded count=\(messages.count)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.chat, "VM · history load failed", error: error)
        }
    }
}

/// Read-only past-conversation viewer. Active sessions show a "Continue
/// chat" CTA that re-emits `INITIATE_CHAT`; the user lands in the live
/// `ChatView` once `CHAT_STARTED` arrives via the realtime store.
struct ChatHistoryView: View {
    let conversation: ConversationSummary

    @Environment(RealtimeStore.self) private var realtime
    @State private var vm: ChatHistoryViewModel
    @State private var resumeRequested: Bool = false
    @State private var showResumeFailureAlert: Bool = false

    private static let dateHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    init(conversation: ConversationSummary) {
        self.conversation = conversation
        _vm = State(initialValue: ChatHistoryViewModel(conversation: conversation))
    }

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: 0) {
                header

                if vm.isLoading && vm.messages.isEmpty {
                    Spacer()
                    ProgressView().tint(.white).controlSize(.large)
                    Spacer()
                } else if vm.messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                if conversation.isActive {
                    resumeFooter
                } else {
                    archivedFooter
                }
            }
        }
        .navigationTitle(conversation.astrologerName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Couldn't resume chat", isPresented: $showResumeFailureAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try again from the astrologer's profile page.")
        }
        .task { await vm.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            AvatarView(
                name: conversation.astrologerName ?? "Astrologer",
                imageURL: conversation.astrologerImage.flatMap(URL.init(string:)),
                gradient: AppTheme.avatarPalette(for: conversation.astroId ?? conversation.id),
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.astrologerName ?? "Astrologer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(conversation.isActive ? .green : .white.opacity(0.65))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var statusLine: String {
        conversation.isActive ? "Active session" : "Past session"
    }

    // MARK: - List

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(vm.messages) { msg in
                    historicalRow(msg)
                        .padding(.horizontal, 14)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func historicalRow(_ msg: HistoricalMessage) -> some View {
        let mediaURL = resolvedMediaURL(for: msg)
        // For media bubbles the `body` text isn't rendered, so blank it out
        // — otherwise the URL string would appear if the renderer ever fell
        // through to the text branch.
        let kind = (msg.messageType ?? "").uppercased()
        let isMedia = kind == "AUDIO" || kind == "IMAGE" || kind == "VOICECALL"

        let bubble = ChatViewModel.ChatMessage(
            id: msg.id,
            body: isMedia ? "" : (msg.message ?? ""),
            isFromUser: msg.fromUser,
            messageType: msg.messageType ?? "TEXT",
            sentAt: msg.date,
            sequenceId: msg.sequenceId,
            astroId: msg.astroId,
            mediaURL: mediaURL,
            audioDurationSeconds: msg.audioDuration,
            callSessionStatus: msg.callSessionStatus,
            callFormFactor: msg.formFactor
        )
        return MessageBubble(message: bubble)
    }

    /// Resolve the playback / image URL from whichever field the wire used.
    /// - audio: `audioUrl` first, then `message` (astro audio messages put
    ///   the URL in `message`).
    /// - voiceCall: the recording URL lives in `message` for ended calls.
    /// - image: first entry of `mediaUrls`.
    private func resolvedMediaURL(for msg: HistoricalMessage) -> URL? {
        let kind = (msg.messageType ?? "").uppercased()
        switch kind {
        case "AUDIO":
            if let s = msg.audioUrl, let url = URL(string: s) { return url }
            return msg.message.flatMap(URL.init(string:))
        case "VOICECALL":
            return msg.message.flatMap(URL.init(string:))
        case "IMAGE":
            return msg.mediaUrls?.first.flatMap(URL.init(string:))
        default:
            return nil
        }
    }

    // MARK: - Empty / archived / resume

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.55))
            Text(vm.errorMessage ?? "No messages in this conversation")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(vm.errorMessage == nil ? 0.65 : 0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var archivedFooter: some View {
        HStack(spacing: 10) {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(.white.opacity(0.65))
            Text("This chat has ended. Open the astrologer's profile to start a new one.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .padding(12)
    }

    private var resumeFooter: some View {
        Button {
            resumeChat()
        } label: {
            HStack(spacing: 8) {
                if resumeRequested {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(resumeRequested ? "Reopening…" : "Continue chat")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(AppTheme.pinkAccent)
        .disabled(resumeRequested)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    private func resumeChat() {
        guard let astroId = conversation.astroId, !resumeRequested else { return }
        resumeRequested = true
        Task {
            // Re-emit INITIATE_CHAT. The realtime store sets `activeChat`
            // when CHAT_STARTED arrives; the user can then reopen the live
            // ChatView from Home / NotificationCenter. We don't push the
            // live ChatView from here because it expects an `AstrologerAPI`
            // which we'd have to fetch separately.
            await NeoAstroSocket.shared.emit(
                .initiateChat,
                payload: InitiateChatPayload(astroId: astroId, continueSession: true)
            )
            // Give the server a beat — most responses land sub-second.
            try? await Task.sleep(for: .seconds(2))
            if realtime.activeChat == nil {
                showResumeFailureAlert = true
            }
            resumeRequested = false
        }
    }
}
