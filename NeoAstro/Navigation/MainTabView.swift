import SwiftUI

struct MainTabView: View {
    enum AppTab: Hashable { case home, horoscope, panchang, more, search }

    @State private var selection: AppTab = .home
    @Environment(DeepLinkRouter.self) private var deepLinks

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "sparkles", value: AppTab.home) {
                HomeView()
            }

            Tab("Horoscope", systemImage: "moon.stars.fill", value: AppTab.horoscope) {
                HoroscopeView()
            }

            Tab("Panchang", systemImage: "sun.and.horizon.fill", value: AppTab.panchang) {
                PanchangView()
            }

            Tab("More", systemImage: "ellipsis.circle.fill", value: AppTab.more) {
                MoreView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                SearchView(onClose: { selection = .home })
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppTheme.pinkAccent)
        .onChange(of: deepLinks.intent) { _, newValue in
            // Tab-level routing only. The destination view consumes the
            // intent in its own `onChange` to avoid races where multiple
            // observers all try to clear it.
            switch newValue {
            case .wallet, .deposit:
                selection = .more   // Wallet lives behind the More tab today
            case .freeAsk, .astrologerProfile, .chatWith:
                selection = .home   // HomeView owns these intents
            case nil:
                break
            }
        }
    }
}
