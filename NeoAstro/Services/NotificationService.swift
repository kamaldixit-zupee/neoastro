import Foundation
import UIKit

enum NotificationService {

    // MARK: - Push token

    /// Sends the APNs device token (hex string) to the backend's `fcmToken`
    /// endpoint. Despite the field name, the server accepts the raw APNs
    /// token; it routes through the same notification fan-out as Android.
    static func uploadAPNsToken(_ token: String) async throws {
        let body = FCMTokenBody(
            fcmToken: token,
            platform: DeviceInfo.platform,
            appVersion: DeviceInfo.buildVersionName,
            deviceId: DeviceInfo.prefixedSerialNumber
        )
        AppLog.info(.api, "→ uploadAPNsToken (\(token.prefix(8))…)")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/misc/fcmToken",
            method: .POST,
            body: body
        ))
        AppLog.info(.api, "← uploadAPNsToken ok")
    }

    // MARK: - Notification center

    static func list() async throws -> NotificationListResponse {
        try await APIClient.shared.send(.init(
            path: "/v1.0/user/getNotificationRequestsDetail",
            method: .GET
        ), as: NotificationListResponse.self)
    }

    static func markRead(notificationId: String) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/misc/readNotification",
            method: .GET,
            query: ["notificationId": notificationId]
        ))
    }

    static func clear(notificationId: String) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/misc/clearNotification",
            method: .POST,
            body: ClearNotificationBody(notificationId: notificationId)
        ))
    }

    static func clearAll() async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/misc/clearAllNotifications",
            method: .POST,
            body: EmptyNotificationBody()
        ))
    }

    // MARK: - In-app nudges

    static func nudges(forScreen screenName: String) async throws -> [NudgeItem] {
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/misc/getNudgesByScreenName",
            method: .POST,
            body: NudgeListBody(screenName: screenName)
        ), as: NudgeListResponse.self)
        return result.nudges ?? []
    }

    static func markNudgeShown(_ nudgeId: String) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/setUserNudgeShown",
            method: .POST,
            body: NudgeShownBody(nudgeId: nudgeId)
        ))
    }

    // MARK: - System push registration

    /// Asks the user for push permission and (if granted) registers with
    /// APNs. The token is delivered async via `AppDelegate`.
    @MainActor
    static func requestAndRegisterPushAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            AppLog.info(.api, "push auth granted=\(granted)")
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            AppLog.error(.api, "push auth request failed", error: error)
        }
    }
}
