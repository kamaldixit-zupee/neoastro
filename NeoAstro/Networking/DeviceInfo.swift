import Foundation
import UIKit

enum DeviceInfo {
    /// Match zupee's app identifier so the backend recognises requests as the
    /// official client. Despite the iOS bundle id being different, every
    /// `appname` / `packageName` / `appPackageName` field on the wire must be
    /// this value.
    static let zupeeAppName = "com.neoastro.android"

    /// Numeric build code zupee servers expect.
    static let buildVersionCode = "512"

    /// Human-readable version string zupee servers expect.
    static let buildVersionName = "1.2512.07_ASTRO_IOS"

    static var rawDeviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown-ios-device"
    }

    /// Zupee body fields (`DeviceId`, `SerialNumber`, `uniqueDeviceId`) use a
    /// prefixed serial: `<packageName>_<UUID>`. Match that.
    static var prefixedSerialNumber: String { "\(zupeeAppName)_\(rawDeviceId)" }

    static var platform: String { "ios" }
    static var iOSVersion: String { UIDevice.current.systemVersion }

    /// Wire language code: prefer the user's explicit picker selection (set by
    /// `LanguageSelectionView`), then fall back to the system locale.
    static var language: String {
        TokenStore.shared.language
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
    }
}
