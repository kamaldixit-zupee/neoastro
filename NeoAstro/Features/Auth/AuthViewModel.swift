import SwiftUI
import Observation

@Observable
@MainActor
final class AuthViewModel {
    enum Stage { case login, otp, authenticated }

    var stage: Stage
    var mobileNumber: String = ""
    var otp: String = ""
    var resendSecondsRemaining: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?

    init() {
        self.stage = TokenStore.shared.isAuthenticated ? .authenticated : .login
        self.mobileNumber = TokenStore.shared.mobileNumber ?? ""
    }

    var isMobileValid: Bool {
        let digits = mobileNumber.filter(\.isNumber)
        return digits.count == 10 && (digits.first.map { "6789".contains($0) } ?? false)
    }

    var isOTPValid: Bool {
        otp.filter(\.isNumber).count == 6
    }

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

    func verifyOTP() {
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
                stage = .authenticated
                AppLog.info(.auth, "VM · verifyOTP success → MainTabView, userId=\(result.userId ?? "?")")
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

    func logout() {
        AppLog.info(.auth, "VM · logout")
        AuthService.logout()
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
