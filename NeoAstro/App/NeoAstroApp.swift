import SwiftUI

@main
struct NeoAstroApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var auth: AuthViewModel
    @State private var config: AppConfigStore
    @State private var realtime: RealtimeStore
    @State private var deepLinks: DeepLinkRouter

    init() {
        AppLog.banner("NeoAstro launching")
        AppLog.info(.auth, "env=\(APIEnvironment.current.name) baseURL=\(APIEnvironment.current.baseURL.absoluteString)")
        AppLog.info(.auth, "deviceId=\(DeviceInfo.prefixedSerialNumber) appName=\(DeviceInfo.zupeeAppName) version=\(DeviceInfo.buildVersionCode)/\(DeviceInfo.buildVersionName)")
        AppLog.info(.auth, "hasStoredToken=\(TokenStore.shared.isAuthenticated) language=\(TokenStore.shared.language ?? "<unset>")")
        _auth = State(wrappedValue: AuthViewModel())
        _config = State(wrappedValue: AppConfigStore())
        _realtime = State(wrappedValue: RealtimeStore())
        _deepLinks = State(wrappedValue: DeepLinkRouter())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(config)
                .environment(realtime)
                .environment(deepLinks)
                .task(id: auth.stage) {
                    // Open the socket once the user reaches the main tabs;
                    // tear it down whenever we drop back to login or splash.
                    if auth.stage == .authenticated {
                        await realtime.start()
                    } else if auth.stage == .login || auth.stage == .splash {
                        await realtime.stop()
                    }
                }
                .onOpenURL { url in
                    deepLinks.handle(url: url)
                }
        }
    }
}
