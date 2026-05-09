import SwiftUI
import Observation

@Observable
@MainActor
final class AuthViewModel {
    enum Stage {
        case splash
        case languagePicker
        case login
        case otp
        case onboarding
        case authenticated
    }

    var stage: Stage
    var mobileNumber: String = ""
    var otp: String = ""
    var resendSecondsRemaining: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?

    init() {
        // Always start at splash — `routeAfterBootstrap(using:)` decides where
        // to go once `AppConfigStore.bootstrap()` returns.
        self.stage = .splash
        self.mobileNumber = TokenStore.shared.mobileNumber ?? ""
    }

    var isMobileValid: Bool {
        let digits = mobileNumber.filter(\.isNumber)
        return digits.count == 10 && (digits.first.map { "6789".contains($0) } ?? false)
    }

    var isOTPValid: Bool {
        otp.filter(\.isNumber).count == 6
    }

    // MARK: - Routing

    /// Called by `SplashView` once `AppConfigStore.bootstrap()` finishes.
    /// Decides whether to show the language picker, login, onboarding, or
    /// the main tabs.
    func routeAfterBootstrap(using config: AppConfigStore) {
        if TokenStore.shared.language == nil {
            AppLog.info(.auth, "route → languagePicker (no stored language)")
            stage = .languagePicker
            return
        }

        if !TokenStore.shared.isAuthenticated {
            AppLog.info(.auth, "route → login (no token)")
            stage = .login
            return
        }

        if config.needsOnboarding {
            AppLog.info(.auth, "route → onboarding")
            stage = .onboarding
            return
        }

        AppLog.info(.auth, "route → authenticated")
        stage = .authenticated
    }

    /// Called by `LanguageSelectionView` after the user picks + persists.
    func languageSelected() {
        if TokenStore.shared.isAuthenticated {
            // We don't know onboarding status here without re-running bootstrap;
            // a logged-in user reaching this stage is uncommon (only happens if
            // we wipe the language Keychain entry). Send them to splash so the
            // store re-evaluates rather than guessing.
            stage = .splash
        } else {
            stage = .login
        }
    }

    /// Called by `OnboardingViewModel` after `setOnboardingCompleted` succeeds.
    func onboardingCompleted() {
        AppLog.info(.auth, "onboarding completed → authenticated")
        stage = .authenticated
    }

    // MARK: - Auth flow

    func sendOTP(resend: Bool = false) {
        guard isMobileValid else {
            AppLog.warn(.auth, "sendOTP blocked: invalid mobile=\(mobileNumber)")
            return
        }
        isLoading = true
        errorMessage = nil
        AppLog.info(.auth, "VM · sendOTP start phone=\(mobileNumber) resend=\(resend)")
        Task {
            do {
                try await AuthService.requestOTP(phoneNumber: mobileNumber, resend: resend)
                otp = ""
                stage = .otp
                startResendTimer()
                AppLog.info(.auth, "VM · sendOTP success → OTP screen")
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                AppLog.error(.auth, "VM · sendOTP failed", error: error)
            }
            isLoading = false
        }
    }

    func verifyOTP(config: AppConfigStore) {
        guard isOTPValid else {
            AppLog.warn(.auth, "verifyOTP blocked: invalid otp len=\(otp.count)")
            return
        }
        isLoading = true
        errorMessage = nil
        AppLog.info(.auth, "VM · verifyOTP start phone=\(mobileNumber) otpLen=\(otp.count)")
        Task {
            do {
                let result = try await AuthService.authenticate(phone: mobileNumber, otp: otp)
                AppLog.info(.auth, "VM · verifyOTP success userId=\(result.userId ?? "?")")
                // Re-bootstrap: now that we have a token, fetch post-signup +
                // user details so we can route onboarding-vs-tabs correctly.
                await config.bootstrap()
                routeAfterBootstrap(using: config)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                AppLog.error(.auth, "VM · verifyOTP failed", error: error)
            }
            isLoading = false
        }
    }

    func backToLogin() {
        stage = .login
        errorMessage = nil
    }

    func logout(config: AppConfigStore) {
        AppLog.info(.auth, "VM · logout")
        AuthService.logout()
        config.clear()
        mobileNumber = ""
        otp = ""
        errorMessage = nil
        stage = .login
    }

    private func startResendTimer() {
        resendSecondsRemaining = 30
        Task { @MainActor in
            while resendSecondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                resendSecondsRemaining -= 1
            }
        }
    }
}
