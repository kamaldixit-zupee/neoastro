import Foundation
import Observation

/// App-level config + bootstrap state.
///
/// Holds the pre-signup and post-signup config payloads plus the user details
/// needed to decide whether onboarding is required. Owned by `NeoAstroApp`
/// and injected via `.environment(...)`. ViewModels read from it; only the
/// store mutates itself.
@Observable
@MainActor
final class AppConfigStore {

    // MARK: - State

    var preSignup: PreSignupConfig?
    var postSignup: PostSignupConfig?
    var userDetails: UserDetails?

    var isBootstrapping: Bool = false
    var bootstrapError: String?

    // MARK: - Derived

    var supportedLanguages: [PreSignupConfig.SupportedLanguage] {
        preSignup?.supportedLanguages?.isEmpty == false
            ? preSignup!.supportedLanguages!
            : PreSignupConfig.fallbackLanguages
    }

    /// Whether the user must go through the birth-details questionnaire
    /// before reaching the main tabs. Derived from server flag first, then
    /// the local Keychain marker, then a heuristic on stored DOB.
    var needsOnboarding: Bool {
        if let serverFlag = postSignup?.isOnboardingCompleted {
            return !serverFlag
        }
        if TokenStore.shared.onboardingCompleted { return false }
        if let dob = userDetails?.dateOfBirth, !dob.isEmpty { return false }
        return true
    }

    var isMaintenanceMode: Bool { preSignup?.maintenanceMode == true }

    // MARK: - Bootstrap

    /// Single source of truth for cold-start data load. Idempotent — safe to
    /// call again on retry.
    func bootstrap() async {
        isBootstrapping = true
        bootstrapError = nil
        AppLog.info(.config, "bootstrap start authed=\(TokenStore.shared.isAuthenticated)")

        // 1. Pre-signup config — best effort. We tolerate failure (we have
        //    fallback languages and can still let the user log in).
        do {
            preSignup = try await ConfigService.preSignUp()
        } catch {
            AppLog.error(.config, "preSignUp failed", error: error)
            // do NOT set bootstrapError — pre-signup failure is recoverable.
        }

        // 2. If authenticated, fetch user details + post-signup config in
        //    parallel to decide onboarding routing.
        if TokenStore.shared.isAuthenticated {
            async let detailsTask = fetchUserDetails()
            async let postTask = fetchPostSignup()
            _ = await [detailsTask, postTask]
        }

        AppLog.info(.config, "bootstrap done needsOnboarding=\(needsOnboarding) maintenance=\(isMaintenanceMode)")
        isBootstrapping = false
    }

    private func fetchUserDetails() async {
        do {
            userDetails = try await ProfileService.getUserDetails()
        } catch {
            AppLog.error(.config, "getUserDetails failed", error: error)
        }
    }

    private func fetchPostSignup() async {
        do {
            postSignup = try await ConfigService.postSignUp()
        } catch {
            AppLog.error(.config, "postSignUp failed", error: error)
        }
    }

    /// Reset on logout so the next session starts clean.
    func clear() {
        userDetails = nil
        postSignup = nil
        bootstrapError = nil
    }
}
