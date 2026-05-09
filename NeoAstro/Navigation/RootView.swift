import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(AppConfigStore.self) private var config
    @Environment(RealtimeStore.self) private var realtime

    var body: some View {
        ZStack {
            CosmicBackground()

            switch auth.stage {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .languagePicker:
                LanguageSelectionView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .login:
                LoginView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            case .otp:
                OTPView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .onboarding:
                OnboardingView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .authenticated:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.45), value: auth.stage)
        .onChange(of: auth.stage) { _, newValue in
            AppLog.info(.auth, "stage → \(String(describing: newValue))")
        }
        // Incoming-call full-screen surface, mounted at root so it appears
        // regardless of which tab the user is on. Driven entirely by
        // `RealtimeStore.incomingCall` — the realtime layer sets it on
        // INCOMING_CALL_REQUEST and clears it on accept/reject/cancel/end.
        .fullScreenCover(item: incomingCallBinding()) { payload in
            IncomingCallView(
                payload: payload,
                onAccept: { handleAccept(payload) },
                onReject: { handleReject(payload) }
            )
        }
    }

    // MARK: - Incoming call routing

    private func incomingCallBinding() -> Binding<IdentifiedIncomingCall?> {
        Binding(
            get: {
                realtime.incomingCall.map { IdentifiedIncomingCall(payload: $0) }
            },
            set: { newValue in
                if newValue == nil { realtime.incomingCall = nil }
            }
        )
    }

    private func handleAccept(_ payload: IncomingCallRequestPayload) {
        AppLog.info(.chat, "incoming call accepted callSessionId=\(payload.callSessionId ?? "?")")
        // TODO (Batch 4b): bridge into Agora — join the channel using
        // payload.token + payload.channelName, transition to in-call UI.
        realtime.incomingCall = nil
    }

    private func handleReject(_ payload: IncomingCallRequestPayload) {
        AppLog.info(.chat, "incoming call rejected callSessionId=\(payload.callSessionId ?? "?")")
        realtime.incomingCall = nil
    }
}

/// Wraps `IncomingCallRequestPayload` so we can use `.fullScreenCover(item:)`
/// without requiring the payload itself to conform to `Identifiable` (the
/// payload's primary key — `callSessionId` — is optional in the wire shape).
private struct IdentifiedIncomingCall: Identifiable {
    let payload: IncomingCallRequestPayload
    var id: String { payload.callSessionId ?? "incoming-call" }
}
