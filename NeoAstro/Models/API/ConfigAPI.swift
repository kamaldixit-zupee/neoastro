import Foundation

// MARK: - Pre-signup config (anonymous, before login)

struct PreSignupConfig: Decodable {
    let supportedLanguages: [SupportedLanguage]?
    let maintenanceMode: Bool?
    let maintenanceMessage: String?
    let appUpdate: AppUpdateInfo?

    struct SupportedLanguage: Decodable, Hashable, Identifiable {
        let code: String
        let name: String?
        let nativeName: String?

        var id: String { code }
        var displayPrimary: String { nativeName ?? name ?? code.uppercased() }
        var displaySecondary: String? {
            guard let name, name != nativeName else { return nil }
            return name
        }
    }

    struct AppUpdateInfo: Decodable {
        let minVersion: String?
        let recommendedVersion: String?
        let isForce: Bool?
        let message: String?
    }

    /// Hard-coded fallback so the language picker still has options if the
    /// pre-signup config call fails (offline first-launch).
    static let fallbackLanguages: [SupportedLanguage] = [
        .init(code: "en", name: "English", nativeName: "English"),
        .init(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
        .init(code: "mr", name: "Marathi", nativeName: "मराठी"),
        .init(code: "ta", name: "Tamil", nativeName: "தமிழ்"),
        .init(code: "te", name: "Telugu", nativeName: "తెలుగు"),
        .init(code: "bn", name: "Bengali", nativeName: "বাংলা"),
        .init(code: "gu", name: "Gujarati", nativeName: "ગુજરાતી"),
        .init(code: "kn", name: "Kannada", nativeName: "ಕನ್ನಡ"),
        .init(code: "pa", name: "Punjabi", nativeName: "ਪੰਜਾਬੀ"),
        .init(code: "ml", name: "Malayalam", nativeName: "മലയാളം")
    ]
}

// MARK: - Post-signup config (authenticated)

struct PostSignupConfig: Decodable {
    let isOnboardingCompleted: Bool?
    let userExperience: String?
    let nudgeConfig: NudgeConfig?

    struct NudgeConfig: Decodable {
        let showFreeAskNudge: Bool?
        let showRechargeNudge: Bool?
    }
}

// MARK: - Onboarding submission

/// Body for `POST /v1.0/user/submitAstroUserDetails`. All fields are optional
/// so the server can accept partial submissions during the multi-step flow,
/// but the iOS submit happens only on the final step with everything filled.
struct AstroUserDetailsBody: Encodable {
    var name: String? = nil
    var dateOfBirth: String? = nil   // ISO 8601 yyyy-MM-dd
    var timeOfBirth: String? = nil   // HH:mm 24h, or nil for "unknown"
    var placeOfBirth: String? = nil
    var birthLatitude: Double? = nil
    var birthLongitude: Double? = nil
    var gender: String? = nil        // "MALE" | "FEMALE" | "OTHER"
    var zupeeUserId: Int? = nil
}

struct OnboardingCompletedBody: Encodable {
    var zupeeUserId: Int? = nil
    var completed: Bool = true
}
