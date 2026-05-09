import Foundation
import Security

final class TokenStore {
    static let shared = TokenStore()

    private let service = "com.neoastro.tokens"
    private enum Key: String {
        case accessToken, refreshToken, userId, zupeeUserId, zodiacName, mobileNumber
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

    var isAuthenticated: Bool { accessToken != nil }

    func clear() {
        for key in [Key.accessToken, .refreshToken, .userId, .zupeeUserId, .zodiacName, .mobileNumber] {
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
