import SwiftUI
import UIKit

struct ChatView: View {
    let astrologer: AstrologerAPI

    @Environment(RealtimeStore.self) private var realtime
    @Environment(DeepLinkRouter.self) private var deepLinks
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ChatViewModel
    @State private var recorder = AudioRecorder()
    @State private var confirmEnd: Bool = false
    @FocusState private var inputFocused: Bool

    init(astrologer: AstrologerAPI) {
        self.astrologer = astrologer
        _vm = State(initialValue: ChatViewModel(astrologer: astrologer))
    }

    var body: some View {
        @Bindable var vm = vm

        ZStack {
            CosmicBackground()

            VStack(spacing: 0) {
                header

                if realtime.activeChat == nil && !vm.hasEndedChat {
                    waitingState
                } else {
                    messageScroll
                }

                if !vm.hasEndedChat {
                    ChatInputBar(
                        text: $vm.draft,
                        focused: $inputFocused,
                        recorder: recorder,
                        onSend: { vm.send() },
                        onTypingTouch: { vm.userTypingTouched() },
                        onVoiceCommit: { captured in vm.sendVoiceNote(captured) },
                        onImage: { data in vm.sendImage(data) }
                    )
                } else {
                    endedFooter
                }
            }
        }
        .navigationTitle(astrologer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    confirmEnd = true
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
                .disabled(vm.hasEndedChat)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { inputFocused = false }
                    .font(.body.weight(.semibold))
            }
        }
        .confirmationDialog("End chat?", isPresented: $confirmEnd) {
            Button("End", role: .destructive) {
                vm.endChat()
            }
        } message: {
            Text("This closes the consultation and stops billing.")
        }
        .onAppear {
            vm.wire(realtime: realtime)
        }
        .onDisappear {
            vm.unwire()
        }
    }

    // MARK: - Header (in-screen, not the nav bar — gives us room for status)

    private var header: some View {
        HStack(spacing: 12) {
            AvatarView(
                name: astrologer.name,
                imageURL: astrologer.imageURL,
                gradient: AppTheme.avatarPalette(for: astrologer._id),
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(astrologer.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                statusLine
            }

            Spacer()

            if let chat = realtime.activeChat, !vm.hasEndedChat {
                billingPill(seconds: Int(Date().timeIntervalSince(chat.startedAt)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var statusLine: some View {
        if vm.hasEndedChat {
            Text("Ended")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        } else if realtime.astrologerRecording {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
                Text("Recording…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        } else if vm.isAstroTyping {
            HStack(spacing: 6) {
                Text("Typing")
                    .font(.caption)
                    .foregroundStyle(AppTheme.pinkAccent)
                TypingIndicator()
                    .scaleEffect(0.6)
            }
        } else if realtime.activeChat == nil {
            Text("Waiting for astrologer…")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        } else {
            Text("Live")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
        }
    }

    private func billingPill(seconds: Int) -> some View {
        let mins = seconds / 60
        let secs = seconds % 60
        return Text(String(format: "%02d:%02d", mins, secs))
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(
                .regular.tint(AppTheme.pinkAccent.opacity(0.4)),
                in: .capsule
            )
    }

    /// Tap handler for the Recharge CTA inside a low-balance system bubble.
    /// Reports the click to analytics via the existing socket event, then
    /// hops to Wallet through the deep-link router so the same routing
    /// logic that handles a notification tap kicks in.
    private func handleRechargeFromChat() {
        Task {
            await NeoAstroSocket.shared.emit(.inChatRechargeCtaClicked)
        }
        deepLinks.intent = .wallet
        dismiss()
    }

    // MARK: - Body states

    private var waitingState: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 60)
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            VStack(spacing: 4) {
                Text("Connecting you with \(astrologer.name)…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if let waitlist = realtime.waitlist {
                    Text(waitlist.displayText ?? "You're in the queue.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            if let error = realtime.lastChatInitiationError {
                VStack(spacing: 6) {
                    Text(error.heading ?? "Couldn't start chat")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    if let sub = error.subHeading {
                        Text(sub)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    Button("Close") { dismiss() }
                        .buttonStyle(.glass)
                        .tint(AppTheme.pinkAccent)
                        .padding(.top, 6)
                }
                .padding(20)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
                .padding(.horizontal, 24)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var messageScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vm.messages) { msg in
                        MessageBubble(message: msg, onRecharge: handleRechargeFromChat)
                            .id(msg.id)
                            .padding(.horizontal, 14)
                            .onAppear { vm.messageBecameVisible(msg) }
                    }
                    if vm.isAstroTyping {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .id("typing-row")
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation(.smooth) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var endedFooter: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Chat ended")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Button("Close") { dismiss() }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .padding(12)
    }
}
