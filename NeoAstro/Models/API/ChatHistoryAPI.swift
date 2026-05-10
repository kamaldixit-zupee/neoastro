import Foundation

// MARK: - Conversation list (POST /v1.0/chat/getHistory)

struct GetChatHistoryBody: Encodable {
    var skip: Int = 0
    var limit: Int = 30
}

/// Wire shape: `{ en, response: [ConversationSummary, …] }` — the array is
/// decoded directly via `ResponseOnlyEnvelope<[ConversationSummary]>` in
/// `ChatHistoryService.conversations()`.
struct ConversationSummary: Decodable, Identifiable, Hashable {
    // Wire fields (match the JSON exactly).
    let chatId: String?
    let astrologerId: String?
    let astrologerName: String?
    let astrologerImage: String?
    let message: String?
    let messageType: String?           // text / audio / image / system_*
    let messageTime: Double?
    let unread: Int?
    let sender: String?                // "astro" / "user"
    let online: Bool?
    let consultationCurrentState: String?
    let callSessionStatus: String?
    let mediaUrls: [String]?
    let reachOutMessageCount: Int?
    let status: ConversationStatus?

    // MARK: - Adapters used by view code

    var id: String { chatId ?? astrologerId ?? UUID().uuidString }
    var astroId: String? { astrologerId }
    var lastMessage: String? { message }
    var lastMessageType: String? { messageType }
    var timestamp: Double? { messageTime }
    var unreadCount: Int? { unread }

    var date: Date {
        guard let ts = messageTime else { return .now }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }

    /// "Active" = the astrologer is currently online (green dot in the list).
    /// Backend doesn't expose a per-chat active flag in this payload, so we
    /// rely on the presence/status block.
    var isActive: Bool {
        if let state = status?.state?.uppercased(), state == "ONLINE" { return true }
        return online ?? false
    }

    var displayLastMessage: String {
        let raw = message ?? ""
        switch (messageType ?? "").uppercased() {
        case "AUDIO":  return "🎤 Voice note"
        case "IMAGE":
            return raw.isEmpty ? "📷 Photo" : "📷 \(raw)"
        case "SYSTEM_LOW_BALANCE":
            return raw.isEmpty ? "Low balance reminder" : raw
        case let s where s.hasPrefix("SYSTEM_"):
            return raw.isEmpty ? "System message" : raw
        default:
            return raw
        }
    }
}

struct ConversationStatus: Decodable, Hashable {
    let text: String?
    let state: String?     // ONLINE / OFFLINE / BUSY
    // `style` exists on the wire but is presentation metadata we don't need.
}

// MARK: - Per-astrologer history (POST /v1.0/chat/getHistoryWithAstrologer)

struct GetHistoryWithAstrologerBody: Encodable {
    let astroId: String
    var skip: Int = 0
    var limit: Int = 50
}

/// Wire shape:
/// ```
/// { en, response: { chatHistory: { "2026-05-07": [msg, msg], "2026-05-08": [msg] }, ... } }
/// ```
/// Backend buckets messages by date string. We flatten them into a single
/// time-sorted array via the `messages` adapter so view code stays simple.
struct ChatHistoryWithAstrologerResponse: Decodable {
    let chatHistory: [String: [HistoricalMessage]]?
    let astrologer: ConversationAstrologerLite?
    let chatId: String?

    var messages: [HistoricalMessage] {
        (chatHistory?.values.flatMap { $0 } ?? [])
            .sorted { $0.date < $1.date }
    }
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
    let messageType: String?         // text / audio / image / voiceCall
    let createdAt: Double?
    let sequenceId: Int?
    let isFromUser: Bool?
    let sender: String?              // "user" / "astro"
    let astroId: String?
    let audioUrl: String?
    let audioDuration: Int?
    let mediaUrls: [String]?
    let callSessionStatus: String?   // ringing / ongoing / accepted / completed / ended / no_answer / rejected / missed
    let formFactor: String?          // "voice" / "video"

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
