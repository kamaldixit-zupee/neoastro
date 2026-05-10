import SwiftUI
import Observation

@Observable
@MainActor
final class AccountViewModel {
    var profile: UserDetails?
    var settings: [UserSettingsWidget] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isDeleting: Bool = false

    func load() async {
        guard profile == nil && settings.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        AppLog.info(.account, "VM · refresh start")
        isLoading = true
        errorMessage = nil

        // Profile is sourced from the keychain cache populated by auth +
        // onboarding; `viewProfile` is partner-app only and unavailable here.
        profile = TokenStore.shared.cachedUserDetails

        do {
            settings = try await UserSettingsService.fetch()
        } catch {
            AppLog.error(.account, "VM · getUserSettings failed", error: error)
            settings = []
        }

        AppLog.info(.account, "VM · refresh done profile=\(profile?.name ?? "nil") widgets=\(settings.count)")
        isLoading = false
    }

    func deleteAccount() async -> Bool {
        AppLog.info(.account, "VM · deleteAccount start")
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await ProfileService.deleteAccount()
            AppLog.info(.account, "VM · deleteAccount success")
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.account, "VM · deleteAccount failed", error: error)
            return false
        }
    }
}
