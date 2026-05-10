import Foundation

enum ChatHistoryService {

    /// Conversation list. Returns the user's past + active chats sorted by
    /// the server (typically most recent first). The wire shape is
    /// `{ en, response: [ConversationSummary, …] }`, so we decode the array
    /// directly via `ResponseOnlyEnvelope`.
    static func conversations(skip: Int = 0, limit: Int = 30) async throws -> [ConversationSummary] {
        AppLog.info(.chat, "service · conversations skip=\(skip) limit=\(limit)")
        return try await APIClient.shared.send(.init(
            path: "/v1.0/chat/getHistory",
            method: .POST,
            body: GetChatHistoryBody(skip: skip, limit: limit)
        ), as: [ConversationSummary].self)
    }

    /// Full message history with one astrologer.
    static func messages(
        with astroId: String,
        skip: Int = 0,
        limit: Int = 50
    ) async throws -> ChatHistoryWithAstrologerResponse {
        AppLog.info(.chat, "service · history with astroId=\(astroId)")
        return try await APIClient.shared.send(.init(
            path: "/v1.0/chat/getHistoryWithAstrologer",
            method: .POST,
            body: GetHistoryWithAstrologerBody(astroId: astroId, skip: skip, limit: limit)
        ), as: ChatHistoryWithAstrologerResponse.self)
    }

    /// Delete the conversation with one astrologer.
    static func deleteHistory(with astroId: String) async throws {
        AppLog.info(.chat, "service · deleteHistory astroId=\(astroId)")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/chat/deleteChatHistory",
            method: .POST,
            body: DeleteChatHistoryBody(astroId: astroId)
        ))
    }

    /// Wipe every conversation for the current user.
    static func deleteAllHistory() async throws {
        AppLog.info(.chat, "service · deleteAllHistory")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/chat/deleteAllChatHistory",
            method: .POST,
            body: EmptyChatHistoryBody()
        ))
    }
}
