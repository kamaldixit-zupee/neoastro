import SwiftUI

@main
struct NeoAstroApp: App {
    @State private var auth: AuthViewModel

    init() {
        AppLog.banner("NeoAstro launching")
        AppLog.info(.auth, "env=\(APIEnvironment.current.name) baseURL=\(APIEnvironment.current.baseURL.absoluteString)")
        AppLog.info(.auth, "deviceId=\(DeviceInfo.prefixedSerialNumber) appName=\(DeviceInfo.zupeeAppName) version=\(DeviceInfo.buildVersionCode)/\(DeviceInfo.buildVersionName)")
        AppLog.info(.auth, "hasStoredToken=\(TokenStore.shared.isAuthenticated)")
        _auth = State(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
        }
    }
}
