import Foundation
import Observation

/// Single, observable holder for the latest deep-link intent. Set from
/// either a custom-scheme URL (`neoastro://…`) or a notification tap, then
/// consumed by whichever feature view owns the destination — typically
/// `MainTabView`, `HomeView`, or `WalletView`.
///
/// Deep links are queued before the user is authenticated and replayed
/// after `auth.stage == .authenticated`, so a notification that lands while
/// the user is on the login screen still routes once they get in.
@Observable
@MainActor
final class DeepLinkRouter {

    enum Intent: Hashable {
        case wallet
        case freeAsk
        case astrologerProfile(astroId: String)
        case chatWith(astroId: String)
        case deposit(amount: Int)
        case notifications
    }

    /// Latest intent. Views observe and consume.
    var intent: Intent?

    // MARK: - Entry points

    /// Handle a `neoastro://…` URL from `.onOpenURL` (foregrounded by tap on
    /// a deep link, e.g. from Mail or another app). Returns `true` if we
    /// recognised the URL.
    @discardableResult
    func handle(url: URL) -> Bool {
        guard let parsed = parse(url: url) else {
            AppLog.warn(.api, "deeplink unrecognised url=\(url.absoluteString)")
            return false
        }
        AppLog.info(.api, "deeplink intent=\(String(describing: parsed))")
        intent = parsed
        return true
    }

    /// Handle a deep link extracted from a remote-notification payload's
    /// `deepLink` / `link` key (set in `AppDelegate`'s tap callback).
    @discardableResult
    func handle(deepLink string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return handle(url: url)
    }

    /// Drain — feature views should call this once they've routed.
    func consume() -> Intent? {
        let value = intent
        intent = nil
        return value
    }

    // MARK: - Parsing

    /// `neoastro://wallet`
    /// `neoastro://ask-free-question`
    /// `neoastro://astrologer-profile/{astroId}`
    /// `neoastro://chat/{astroId}`
    /// `neoastro://deposit/{amount}`
    /// `neoastro://notifications`
    private func parse(url: URL) -> Intent? {
        guard url.scheme == "neoastro" else { return nil }

        // `URL.host` carries the first path component for custom schemes
        // (`neoastro://wallet` → host == "wallet"). Subsequent path
        // components live in `pathComponents` minus the leading "/".
        let host = url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "wallet":
            return .wallet
        case "notifications":
            return .notifications
        case "ask-free-question", "free-ask", "freeask":
            return .freeAsk
        case "astrologer-profile":
            if let id = pathComponents.first { return .astrologerProfile(astroId: id) }
        case "chat":
            if let id = pathComponents.first { return .chatWith(astroId: id) }
        case "deposit":
            if let raw = pathComponents.first, let amount = Int(raw) {
                return .deposit(amount: amount)
            }
        default:
            break
        }
        return nil
    }
}
