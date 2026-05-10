import SwiftUI

/// Free Chat waiting screen. Triggers the REST match endpoint on appear,
/// then waits for `FREE_CHAT_WAITLIST` → `FREE_CHAT_ASTRO_ID` → `CHAT_STARTED`
/// to land. Once an astrologer is assigned and CHAT_STARTED arrives, the
/// caller routes the user into `ChatView`.
struct FreeChatWaitingView: View {
    let onAssigned: (String) -> Void  // astroId
    let onCancel: () -> Void

    @Environment(RealtimeStore.self) private var realtime
    @State private var ringPulse: Bool = false
    @State private var hasMatched: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: AppTheme.sectionSpacing) {
                Spacer()

                pulsingHero

                Text(headline)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let text = realtime.freeChatWaitlistText {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                Button(action: cancel) {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                .tint(.white.opacity(0.18))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .navigationTitle("Free Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            ringPulse = true
            guard !hasMatched else { return }
            hasMatched = true
            await startMatching()
        }
        .task(id: realtime.freeChatAssignedAstroId) {
            if let astroId = realtime.freeChatAssignedAstroId {
                // Also emit INITIATE_FREE_CHAT so the server knows the user
                // is committed to the assigned astrologer; some flows also
                // require INITIATE_CHAT to follow before CHAT_STARTED.
                if let zuid = TokenStore.shared.zupeeUserId {
                    await NeoAstroSocket.shared.emit(
                        .initiateFreeChat,
                        payload: InitiateFreeChatPayload(zupeeUserId: zuid)
                    )
                }
                onAssigned(astroId)
            }
        }
    }

    private var headline: String {
        if realtime.freeChatAssignedAstroId != nil {
            return "Connecting you to your astrologer…"
        } else if realtime.freeChatWaitlistText != nil {
            return "You're in the queue"
        }
        return "Finding the right astrologer for you…"
    }

    private var pulsingHero: some View {
        ZStack {
            Circle()
                .fill(AppTheme.pinkAccent.opacity(0.15))
                .frame(width: 200, height: 200)
                .scaleEffect(ringPulse ? 1.18 : 0.9)
                .opacity(ringPulse ? 0 : 0.7)
                .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: ringPulse)

            Image(systemName: "person.2.wave.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 110, height: 110)
                .glassEffect(.regular, in: .circle)
        }
    }

    private func startMatching() async {
        do {
            try await FreeAskService.matchFreeChat()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.chat, "free chat match failed", error: error)
        }
    }

    private func cancel() {
        realtime.resetFreeChat()
        onCancel()
    }
}
