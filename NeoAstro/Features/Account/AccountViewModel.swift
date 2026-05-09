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

        async let profileTask: UserDetails? = {
            do {
                return try await ProfileService.viewProfile()
            } catch {
                AppLog.error(.account, "VM · viewProfile failed", error: error)
                return nil
            }
        }()

        async let settingsTask: [UserSettingsWidget] = {
            do {
                return try await UserSettingsService.fetch()
            } catch {
                AppLog.error(.account, "VM · getUserSettings failed", error: error)
                return []
            }
        }()

        let (loadedProfile, loadedSettings) = await (profileTask, settingsTask)
        profile = loadedProfile
        settings = loadedSettings

        if loadedProfile == nil && loadedSettings.isEmpty {
            errorMessage = "Couldn't load your profile. Pull to refresh."
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
