import SwiftUI

/// Cold-start screen. Triggers `AppConfigStore.bootstrap()` and asks the
/// `AuthViewModel` to route once the work completes. The visible duration is
/// clamped to a minimum so the brand mark never flashes — bootstrap that
/// finishes faster waits for the floor; bootstrap that runs long shows the
/// progress hint instead of leaving the screen empty.
struct SplashView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(AppConfigStore.self) private var config

    @State private var hasStarted = false
    @State private var showLogo = false
    @State private var pulseUp = false

    private let minimumVisibleDuration: TimeInterval = 0.9

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 160, height: 160)
                    .blur(radius: 36)
                    .opacity(pulseUp ? 0.55 : 0.35)
                    .animation(.smooth(duration: 1.6).repeatForever(autoreverses: true), value: pulseUp)

                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(20)
                    .glassEffect(.regular, in: .circle)
                    .scaleEffect(showLogo ? 1.0 : 0.6)
                    .opacity(showLogo ? 1.0 : 0.0)
                    .animation(.smooth(duration: 0.55), value: showLogo)
            }

            VStack(spacing: 6) {
                Text("NeoAstro")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text("Cosmic guidance, on demand")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .opacity(showLogo ? 1.0 : 0.0)
            .animation(.smooth(duration: 0.55).delay(0.15), value: showLogo)

            Spacer()

            ProgressView()
                .tint(.white.opacity(0.6))
                .opacity(config.isBootstrapping ? 1.0 : 0.0)
                .animation(.smooth, value: config.isBootstrapping)
                .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard !hasStarted else { return }
            hasStarted = true
            showLogo = true
            pulseUp = true
            await runBootstrap()
        }
    }

    private func runBootstrap() async {
        async let bootstrap: () = config.bootstrap()
        async let floor: () = Task.sleep(for: .seconds(minimumVisibleDuration))
        _ = try? await (bootstrap, floor)
        auth.routeAfterBootstrap(using: config)
    }
}
