import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    /// Authoritative list returned by the server.
    private(set) var allAstrologers: [AstrologerAPI] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var searchText: String = ""

    /// Visible list — derived from `allAstrologers` filtered by `searchText`.
    var astrologers: [AstrologerAPI] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return allAstrologers }
        return allAstrologers.filter { astro in
            astro.name.lowercased().contains(q)
                || (astro.qualificationText?.lowercased().contains(q) ?? false)
                || (astro.qualification?.lowercased().contains(q) ?? false)
                || (astro.studies?.contains(where: { $0.lowercased().contains(q) }) ?? false)
                || (astro.languages?.contains(where: { $0.lowercased().contains(q) }) ?? false)
        }
    }

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
