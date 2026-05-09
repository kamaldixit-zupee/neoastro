import Foundation

enum ConfigService {

    /// Anonymous pre-signup config — supported languages, maintenance mode,
    /// app-update hints. Called once on splash before any auth check.
    static func preSignUp() async throws -> PreSignupConfig {
        AppLog.info(.config, "→ preSignUp")
        let result = try await APIClient.shared.send(
            .init(path: "/v1.0/config/preSignUp", method: .GET, requiresAuth: false),
            as: PreSignupConfig.self
        )
        AppLog.info(.config, "← preSignUp ok languages=\(result.supportedLanguages?.count ?? 0) maintenance=\(result.maintenanceMode == true)")
        return result
    }

    struct PostSignupBody: Encodable {
        let zupeeUserId: Int
    }

    /// Authenticated post-signup config — onboarding flag, nudge prefs.
    /// Called after a successful authenticate or whenever the app re-enters
    /// the foreground with valid tokens.
    static func postSignUp() async throws -> PostSignupConfig {
        guard let zupeeUserId = TokenStore.shared.zupeeUserId else { throw APIError.unauthorized }
        AppLog.info(.config, "→ postSignUp zuid=\(zupeeUserId)")
        let result = try await APIClient.shared.send(
            .init(
                path: "/v1.0/config/postSignUp",
                method: .POST,
                body: PostSignupBody(zupeeUserId: zupeeUserId)
            ),
            as: PostSignupConfig.self
        )
        AppLog.info(.config, "← postSignUp ok onboarded=\(result.isOnboardingCompleted == true)")
        return result
    }
}
