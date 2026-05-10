import SwiftUI
import Observation

/// Backs `SearchView`. Loads the full astrologer roster + recent-search ids
/// once, then filters in-memory as the user types — same shape as the RN app
/// (`SearchAstrologer.tsx`'s `realTimeAstrologers` map).
@Observable
@MainActor
final class SearchViewModel {
    var query: String = ""
    private(set) var allAstrologers: [AstrologerAPI] = []
    private(set) var recentIds: [String] = []
    private(set) var isLoadingInitial: Bool = false
    private(set) var loadError: String?

    /// Astrologer cards to render in the recent-search row, in the order
    /// the server returned. Drops ids we don't have full data for.
    var recentAstrologers: [AstrologerAPI] {
        recentIds.compactMap { id in allAstrologers.first(where: { $0._id == id }) }
    }

    /// In-memory filter against `allAstrologers.name`. Empty query → no list.
    var searchResults: [AstrologerAPI] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return allAstrologers.filter { $0.name.lowercased().contains(q) }
    }

    func loadInitial() async {
        guard allAstrologers.isEmpty else {
            await refreshRecent()
            return
        }
        isLoadingInitial = true
        loadError = nil

        async let astrosTask: [AstrologerAPI] = {
            do { return try await AstrologerService.listBest() }
            catch {
                AppLog.error(.search, "VM · listBest failed", error: error)
                return []
            }
        }()
        async let recentTask: [String] = {
            do { return try await AstrologerService.recentSearches() }
            catch {
                AppLog.error(.search, "VM · recentSearches failed", error: error)
                return []
            }
        }()

        let (astros, recent) = await (astrosTask, recentTask)
        allAstrologers = astros
        recentIds = recent
        AppLog.info(.search, "VM · loadInitial astros=\(astros.count) recent=\(recent.count)")
        isLoadingInitial = false
    }

    func refreshRecent() async {
        do {
            recentIds = try await AstrologerService.recentSearches()
        } catch {
            AppLog.error(.search, "VM · refreshRecent failed", error: error)
        }
    }

    /// Best-effort — push to the top of the server-side recent list and
    /// optimistically update the local copy so the row reflects the change
    /// immediately.
    func recordTap(_ astrologer: AstrologerAPI) {
        let id = astrologer._id
        recentIds.removeAll { $0 == id }
        recentIds.insert(id, at: 0)
        Task {
            do { try await AstrologerService.addRecentSearch(astroId: id) }
            catch { AppLog.error(.search, "VM · addRecentSearch failed", error: error) }
        }
    }

    func clearRecent(_ astroId: String? = nil) {
        if let astroId {
            recentIds.removeAll { $0 == astroId }
        } else {
            recentIds.removeAll()
        }
        Task {
            do { try await AstrologerService.clearRecentSearches(astroId: astroId) }
            catch { AppLog.error(.search, "VM · clearRecentSearches failed", error: error) }
        }
    }
}
