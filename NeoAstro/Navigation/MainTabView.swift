import SwiftUI

@Observable
@MainActor
final class HomeSearchCoordinator {
    var requestFocusToken: Int = 0
    func requestFocus() { requestFocusToken &+= 1 }
}

struct MainTabView: View {
    enum AppTab: Hashable { case home, horoscope, panchang, more, search }

    @State private var selection: AppTab = .home
    @State private var searchCoordinator = HomeSearchCoordinator()
    @Environment(DeepLinkRouter.self) private var deepLinks

    private var routedSelection: Binding<AppTab> {
        Binding(
            get: { selection == .search ? .home : selection },
            set: { newValue in
                if newValue == .search {
                    selection = .home
                    searchCoordinator.requestFocus()
                } else {
                    selection = newValue
                }
            }
        )
    }

    var body: some View {
        TabView(selection: routedSelection) {
            Tab("Home", systemImage: "sparkles", value: AppTab.home) {
                HomeView()
                    .environment(searchCoordinator)
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

            Tab(value: AppTab.search, role: .search) {
                HomeView()
                    .environment(searchCoordinator)
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
