import Foundation

enum FreeAskService {

    /// REST fallback for free-ask submission. Realtime path is `FREE_ASK`
    /// emit on the socket; the REST endpoint is what the RN app falls back
    /// to when the socket is offline.
    static func submitFreeAsk(category: FreeAskCategory, question: String) async throws {
        let body = FreeAskRestBody(category: category.rawValue, questionText: question)
        AppLog.info(.chat, "→ free ask submit category=\(category.rawValue)")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/chat/freeAsk",
            method: .POST,
            body: body
        ))
    }

    /// Match for Free Chat. Triggered when the user wants their first
    /// free chat with an astrologer; backend assigns one and the realtime
    /// layer delivers `FREE_CHAT_ASTRO_ID` followed by `CHAT_STARTED`.
    static func matchFreeChat() async throws {
        struct Body: Encodable {
            let zupeeUserId: Int
        }
        guard let zuid = TokenStore.shared.zupeeUserId else { throw APIError.unauthorized }
        AppLog.info(.chat, "→ free chat match zuid=\(zuid)")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/chat/consult-free-chat/match",
            method: .POST,
            body: Body(zupeeUserId: zuid)
        ))
    }
}
