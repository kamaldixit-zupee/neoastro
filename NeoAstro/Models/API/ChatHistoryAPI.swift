import Foundation

// MARK: - Conversation list (POST /v1.0/chat/getHistory)

struct GetChatHistoryBody: Encodable {
    var skip: Int = 0
    var limit: Int = 30
}

struct ChatHistoryListResponse: Decodable {
    let chats: [ConversationSummary]?
    let conversations: [ConversationSummary]?
    let total: Int?

    /// Backend uses either `chats` or `conversations` depending on
    /// endpoint version; expose a single resolved list.
    var resolved: [ConversationSummary] { chats ?? conversations ?? [] }
}

struct ConversationSummary: Decodable, Identifiable, Hashable {
    let _id: String?
    let chatId: String?
    let astroId: String?
    let astrologerName: String?
    let astrologerImage: String?
    let lastMessage: String?
    let lastMessageType: String?       // TEXT / AUDIO / IMAGE / SYSTEM_*
    let timestamp: Double?
    let unreadCount: Int?
    let status: String?                // ENDED / ACTIVE / IN_PROGRESS
    let durationSeconds: Int?
    let totalMessages: Int?

    var id: String { _id ?? chatId ?? "\(astroId ?? UUID().uuidString)" }

    var date: Date {
        guard let ts = timestamp else { return .now }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }

    var isActive: Bool {
        let s = (status ?? "").uppercased()
        return s == "ACTIVE" || s == "IN_PROGRESS"
    }

    var displayLastMessage: String {
        let raw = lastMessage ?? ""
        switch (lastMessageType ?? "").uppercased() {
        case "AUDIO":  return "🎤 Voice note"
        case "IMAGE":  return "📷 Photo"
        case "SYSTEM_LOW_BALANCE":
            return raw.isEmpty ? "Low balance reminder" : raw
        case let s where s.hasPrefix("SYSTEM_"):
            return raw.isEmpty ? "System message" : raw
        default:       return raw
        }
    }
}

// MARK: - Per-astrologer history (POST /v1.0/chat/getHistoryWithAstrologer)

struct GetHistoryWithAstrologerBody: Encodable {
    let astroId: String
    var skip: Int = 0
    var limit: Int = 50
}

struct ChatHistoryWithAstrologerResponse: Decodable {
    let messages: [HistoricalMessage]?
    let total: Int?
    let astrologer: ConversationAstrologerLite?
    let chatId: String?
}

struct ConversationAstrologerLite: Decodable, Hashable {
    let _id: String?
    let name: String?
    let image: String?
    let qualification: String?
}

/// Past message — looks like `AnswerQueryPayload` but covers both the user
/// and the astrologer side (server returns mixed in a single array).
struct HistoricalMessage: Decodable, Identifiable, Hashable {
    let _id: String?
    let message: String?
    let messageType: String?
    let createdAt: Double?
    let sequenceId: Int?
    let isFromUser: Bool?
    let sender: String?              // "USER" / "ASTROLOGER"
    let astroId: String?
    let audioUrl: String?
    let audioDuration: Int?
    let mediaUrls: [String]?

    var id: String { _id ?? UUID().uuidString }
    var date: Date {
        guard let ts = createdAt else { return .now }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }
    var fromUser: Bool {
        if let isFromUser { return isFromUser }
        if let s = sender?.uppercased() { return s == "USER" }
        return false
    }
}

// MARK: - Delete

struct DeleteChatHistoryBody: Encodable {
    let astroId: String
}

struct EmptyChatHistoryBody: Encodable {}
