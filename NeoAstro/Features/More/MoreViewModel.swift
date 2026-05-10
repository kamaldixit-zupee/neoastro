import SwiftUI
import Observation

@Observable
@MainActor
final class MoreViewModel {
    var widgets: [UserSettingsWidget] = []
    var profile: UserDetails?
    var isLoading: Bool = false
    var profileError: String?
    var widgetsError: String?
    var isDeleting: Bool = false

    var hasFatalError: Bool {
        profile == nil && widgets.isEmpty && (profileError != nil || widgetsError != nil)
    }

    func load() async {
        guard widgets.isEmpty && profile == nil else { return }
        await refresh()
    }

    func refresh() async {
        AppLog.info(.account, "More VM · refresh start")
        isLoading = true
        profileError = nil
        widgetsError = nil

        // Profile is sourced from the keychain cache populated by auth +
        // onboarding; `viewProfile` is partner-app only and unavailable here.
        profile = TokenStore.shared.cachedUserDetails

        do {
            widgets = try await UserSettingsService.fetch()
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.account, "More VM · getUserSettings failed msg=\(msg)", error: error)
            widgets = []
            widgetsError = msg
        }

        AppLog.info(.account, "More VM · refresh done widgets=\(widgets.count) profile=\(profile?.name ?? "nil") wErr=\(widgetsError ?? "nil")")
        isLoading = false
    }

    func deleteAccount() async -> Bool {
        AppLog.info(.account, "More VM · deleteAccount start")
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await ProfileService.deleteAccount()
            return true
        } catch {
            widgetsError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.account, "More VM · deleteAccount failed", error: error)
            return false
        }
    }
}
