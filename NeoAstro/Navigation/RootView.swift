import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        ZStack {
            CosmicBackground()

            switch auth.stage {
            case .login:
                LoginView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            case .otp:
                OTPView()
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
    }
}
