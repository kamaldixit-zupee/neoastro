import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    /// Authoritative list returned by the server.
    private(set) var allAstrologers: [AstrologerAPI] = []
    var isLoading: Bool = false
    var errorMessage: String?

    var astrologers: [AstrologerAPI] { allAstrologers }

    func loadInitial() async {
        guard allAstrologers.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        AppLog.info(.home, "VM · refresh start")
        isLoading = true
        errorMessage = nil
        do {
            allAstrologers = try await AstrologerService.listBest()
            AppLog.info(.home, "VM · refresh success count=\(allAstrologers.count)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.home, "VM · refresh failed", error: error)
        }
        isLoading = false
    }
}
