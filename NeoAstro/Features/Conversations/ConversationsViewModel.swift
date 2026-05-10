import SwiftUI
import Observation

@Observable
@MainActor
final class ConversationsViewModel {
    var conversations: [ConversationSummary] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isClearingAll: Bool = false

    func load() async {
        guard conversations.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        AppLog.info(.chat, "VM · conversations refresh")
        do {
            conversations = try await ChatHistoryService.conversations()
            AppLog.info(.chat, "VM · conversations refreshed count=\(conversations.count)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.chat, "VM · conversations refresh failed", error: error)
        }
        isLoading = false
    }

    func delete(_ conversation: ConversationSummary) async {
        guard let astroId = conversation.astroId else { return }
        do {
            try await ChatHistoryService.deleteHistory(with: astroId)
            conversations.removeAll { $0.id == conversation.id }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.chat, "VM · delete conversation failed", error: error)
        }
    }

    func clearAll() async {
        isClearingAll = true
        defer { isClearingAll = false }
        do {
            try await ChatHistoryService.deleteAllHistory()
            conversations.removeAll()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.chat, "VM · clear-all conversations failed", error: error)
        }
    }
}
