import SwiftUI
import Observation

@Observable
@MainActor
final class PanchangViewModel {
    var panchang: Panchang?
    var isLoading: Bool = false
    var errorMessage: String?

    func load() async {
        guard panchang == nil else { return }
        await refresh()
    }

    func refresh() async {
        AppLog.info(.panchang, "VM · refresh start")
        isLoading = true
        errorMessage = nil
        do {
            panchang = try await PanchangService.today()
            AppLog.info(.panchang, "VM · refresh success widgets=\(panchang?.widgets?.count ?? 0) location=\(panchang?.location ?? "?")")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.panchang, "VM · refresh failed", error: error)
        }
        isLoading = false
    }
}
