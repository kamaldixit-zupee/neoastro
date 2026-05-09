import Foundation
import Security

final class TokenStore {
    static let shared = TokenStore()

    private let service = "com.neoastro.tokens"
    private enum Key: String {
        case accessToken, refreshToken, userId, zupeeUserId, zodiacName, mobileNumber, language, onboardingCompleted
    }

    var accessToken: String? {
        get { read(.accessToken) }
        set { write(.accessToken, value: newValue) }
    }

    var refreshToken: String? {
        get { read(.refreshToken) }
        set { write(.refreshToken, value: newValue) }
    }

    var userId: String? {
        get { read(.userId) }
        set { write(.userId, value: newValue) }
    }

    var zupeeUserId: Int? {
        get { Int(read(.zupeeUserId) ?? "") }
        set { write(.zupeeUserId, value: newValue.map(String.init)) }
    }

    var zodiacName: String? {
        get { read(.zodiacName) }
        set { write(.zodiacName, value: newValue) }
    }

    var mobileNumber: String? {
        get { read(.mobileNumber) }
        set { write(.mobileNumber, value: newValue) }
    }

    /// User-selected interface language, set during the language-picker step.
    /// `nil` until the first launch's picker has been completed.
    var language: String? {
        get { read(.language) }
        set { write(.language, value: newValue) }
    }

    /// Marker that the user has finished the birth-details questionnaire on
    /// this device. The server is the source of truth; this is a hint so we
    /// avoid round-tripping `getUserDetails` on every cold launch.
    var onboardingCompleted: Bool {
        get { read(.onboardingCompleted) == "1" }
        set { write(.onboardingCompleted, value: newValue ? "1" : nil) }
    }

    var isAuthenticated: Bool { accessToken != nil }

    func clear() {
        // Note: we deliberately keep `language` after logout — the user's
        // language preference outlives any single account.
        for key in [Key.accessToken, .refreshToken, .userId, .zupeeUserId, .zodiacName, .mobileNumber, .onboardingCompleted] {
            write(key, value: nil)
        }
    }

    private func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }

    private func write(_ key: Key, value: String?) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
        guard let value, let data = value.data(using: .utf8) else { return }
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }
}
