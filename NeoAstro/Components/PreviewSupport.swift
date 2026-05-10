#if DEBUG
import SwiftUI

extension View {
    /// One-shot environment injection for SwiftUI previews. Mirrors the set
    /// of objects `NeoAstroApp` puts into the environment at runtime, so any
    /// feature view can be previewed without per-call boilerplate.
    func previewEnvironment() -> some View {
        self
            .environment(AuthViewModel())
            .environment(AppConfigStore())
            .environment(RealtimeStore())
            .environment(DeepLinkRouter())
            .environment(HomeSearchCoordinator())
    }
}
#endif
