import Foundation

// MARK: - Push token

struct FCMTokenBody: Encodable {
    let fcmToken: String
    let platform: String
    let appVersion: String
    let deviceId: String
}

// MARK: - Notification center

struct NotificationListResponse: Decodable {
    let notifications: [NotificationItem]?
    let unreadCount: Int?
}

struct NotificationItem: Decodable, Identifiable, Hashable {
    let _id: String?
    let title: String?
    let body: String?
    let imageUrl: String?
    let iconUrl: String?
    let type: String?
    let createdTimestamp: Double?
    let isRead: Bool?
    let deepLink: String?
    let category: String?

    var id: String { _id ?? UUID().uuidString }

    var date: Date {
        guard let ts = createdTimestamp else { return .now }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }

    var displayTitle: String { title ?? "NeoAstro" }
    var displayBody: String { body ?? "" }
    var unread: Bool { !(isRead ?? false) }
}

struct ClearNotificationBody: Encodable {
    let notificationId: String
}

struct EmptyNotificationBody: Encodable {}

// MARK: - In-app nudges

struct NudgeListBody: Encodable {
    let screenName: String
}

struct NudgeListResponse: Decodable {
    let nudges: [NudgeItem]?
}

struct NudgeItem: Decodable, Identifiable, Hashable {
    let _id: String?
    let title: String?
    let subtitle: String?
    let iconUrl: String?
    let backgroundColor: String?
    let cta: NudgeCTA?

    var id: String { _id ?? UUID().uuidString }
}

struct NudgeCTA: Decodable, Hashable {
    let displayText: String?
    let value: String?
    let type: String?
    let link: String?
}

struct NudgeShownBody: Encodable {
    let nudgeId: String
}
