import Foundation
import os

enum AppLog {
    private static let subsystem = "com.neoastro.app"

    enum Category: String {
        case api = "api"
        case auth = "auth"
        case home = "home"
        case search = "search"
        case account = "account"
        case wallet = "wallet"
        case horoscope = "horoscope"
        case panchang = "panchang"
        case chat = "chat"
    }

    private static let loggers: [Category: Logger] = {
        var map: [Category: Logger] = [:]
        for c in [Category.api, .auth, .home, .search, .account, .wallet, .horoscope, .panchang, .chat] {
            map[c] = Logger(subsystem: subsystem, category: c.rawValue)
        }
        return map
    }()

    static func info(_ category: Category, _ message: @autoclosure () -> String) {
        let msg = message()
        print("ℹ️ [\(category.rawValue)] \(msg)")
        loggers[category]?.info("\(msg, privacy: .public)")
    }

    static func debug(_ category: Category, _ message: @autoclosure () -> String) {
        let msg = message()
        print("🔍 [\(category.rawValue)] \(msg)")
        loggers[category]?.debug("\(msg, privacy: .public)")
    }

    static func warn(_ category: Category, _ message: @autoclosure () -> String) {
        let msg = message()
        print("⚠️ [\(category.rawValue)] \(msg)")
        loggers[category]?.warning("\(msg, privacy: .public)")
    }

    static func error(_ category: Category, _ message: @autoclosure () -> String, error: Error? = nil) {
        var msg = message()
        if let error { msg += " | error=\(error)" }
        print("❌ [\(category.rawValue)] \(msg)")
        loggers[category]?.error("\(msg, privacy: .public)")
    }

    static func banner(_ title: String) {
        let line = String(repeating: "═", count: 60)
        print("\n\(line)\n  \(title)\n\(line)")
    }
}
