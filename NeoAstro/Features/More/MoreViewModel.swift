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

        async let profileTask: (UserDetails?, String?) = {
            do {
                let p = try await ProfileService.viewProfile()
                return (p, nil)
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                AppLog.error(.account, "More VM · viewProfile failed msg=\(msg)", error: error)
                return (nil, msg)
            }
        }()

        async let widgetsTask: ([UserSettingsWidget], String?) = {
            do {
                let w = try await UserSettingsService.fetch()
                return (w, nil)
            } catch {
                let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                AppLog.error(.account, "More VM · getUserSettings failed msg=\(msg)", error: error)
                return ([], msg)
            }
        }()

        let ((p, pErr), (w, wErr)) = await (profileTask, widgetsTask)
        profile = p
        widgets = w
        profileError = pErr
        widgetsError = wErr

        AppLog.info(.account, "More VM · refresh done widgets=\(w.count) profile=\(p?.name ?? "nil") pErr=\(pErr ?? "nil") wErr=\(wErr ?? "nil")")
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
