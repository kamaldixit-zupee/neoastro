import UIKit
import UserNotifications

/// Bridges UIKit lifecycle into our SwiftUI app for the bits we still need
/// from the system: APNs registration, push tap handling, and the legacy
/// `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
/// callback that the system uses for silent / background payloads.
///
/// Wired in `NeoAstroApp` via `@UIApplicationDelegateAdaptor(AppDelegate.self)`.
///
/// **Project-config TODO** (must be done in Xcode, not via XcodeGen yet):
/// 1. Add the *Push Notifications* capability to the NeoAstro target.
/// 2. Add the *Background Modes → Remote notifications* capability if you
///    want silent pushes to wake the app.
/// 3. Confirm an APNs Auth Key (`.p8`) is uploaded to App Store Connect
///    and the backend is configured with the matching team / key id.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Ask once at launch. The auth prompt will appear if we've never
        // asked; otherwise this resolves immediately with the cached state.
        Task { @MainActor in
            await NotificationService.requestAndRegisterPushAuthorization()
        }
        return true
    }

    // MARK: - APNs token

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hexToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLog.info(.api, "APNs token registered prefix=\(hexToken.prefix(8))…")
        Task {
            do {
                try await NotificationService.uploadAPNsToken(hexToken)
            } catch {
                AppLog.error(.api, "APNs token upload failed", error: error)
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppLog.error(.api, "APNs registration failed", error: error)
    }

    // MARK: - Background payload (silent push)

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        AppLog.info(.api, "remote notification (background) keys=\(userInfo.keys.map { String(describing: $0) })")
        // No work to do today — surface to a queue when realtime / chat lands.
        completionHandler(.noData)
    }
}

// MARK: - Foreground / tap delivery

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Notification arrived while the app is in the foreground. Surface as
    /// a banner + sound; let the cosmic UI handle in-app updates separately.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        AppLog.info(.api, "notification (foreground) id=\(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge, .list])
    }

    /// User tapped a notification. Pulls the deep link out of the payload
    /// and hands it to `DeepLinkRouter`, which queues the intent until the
    /// SwiftUI hierarchy can route on it.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let deepLink = (userInfo["deepLink"] as? String) ?? (userInfo["link"] as? String)
        AppLog.info(.api, "notification tapped deepLink=\(deepLink ?? "<none>")")
        if let deepLink {
            // Hop to MainActor; DeepLinkRouter is @MainActor-isolated.
            Task { @MainActor in
                AppDelegate.deepLinks?.handle(deepLink: deepLink)
            }
        }
        completionHandler()
    }

    /// Bridge the SwiftUI-injected `DeepLinkRouter` so the notification
    /// callback (which runs outside any view) can reach it. Set once in
    /// `RootView.onAppear`.
    @MainActor static var deepLinks: DeepLinkRouter?
}
