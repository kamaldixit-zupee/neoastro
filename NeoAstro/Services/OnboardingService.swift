import Foundation

enum OnboardingService {

    /// `POST /v1.0/user/submitAstroUserDetails` — persists the full birth
    /// detail set used by Kundli / chat onboarding gates.
    static func submitAstroUserDetails(_ body: AstroUserDetailsBody) async throws {
        var body = body
        if body.zupeeUserId == nil { body.zupeeUserId = TokenStore.shared.zupeeUserId }
        AppLog.info(.onboarding, "→ submitAstroUserDetails name=\(body.name ?? "?") dob=\(body.dateOfBirth ?? "?") gender=\(body.gender ?? "?")")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/submitAstroUserDetails",
            method: .POST,
            body: body
        ))
        AppLog.info(.onboarding, "← submitAstroUserDetails ok")
    }

    /// `POST /v1.0/user/setOnboardingCompleted` — flips the server-side
    /// onboarding-done flag. Called once the questionnaire's submit succeeds.
    static func setOnboardingCompleted() async throws {
        var body = OnboardingCompletedBody()
        body.zupeeUserId = TokenStore.shared.zupeeUserId
        AppLog.info(.onboarding, "→ setOnboardingCompleted zuid=\(body.zupeeUserId.map(String.init) ?? "?")")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/setOnboardingCompleted",
            method: .POST,
            body: body
        ))
        TokenStore.shared.onboardingCompleted = true
        AppLog.info(.onboarding, "← setOnboardingCompleted ok")
    }
}
