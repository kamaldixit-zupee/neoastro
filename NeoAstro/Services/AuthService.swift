import Foundation
import UIKit

enum AuthAction: String {
    case signUp = "SignUp"
    case reAuth = "ReAuth"
}

enum AuthService {
    static func requestOTP(phoneNumber: String, action: AuthAction = .signUp, resend: Bool = false) async throws {
        AppLog.banner("AUTH · request OTP")
        AppLog.info(.auth, "phone=+91\(phoneNumber) action=\(action.rawValue) resend=\(resend)")

        let body = RequestOTPBody(
            deviceUniqueId: DeviceInfo.rawDeviceId,
            phoneNumber: phoneNumber,
            action: action.rawValue,
            appPackageName: DeviceInfo.zupeeAppName,
            userResendOtp: resend,
            isConsultationCampaign: true
        )
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/requestSignupOtp",
            method: .POST,
            body: body,
            requiresAuth: false
        ))
        AppLog.info(.auth, "requestOTP success")
    }

    static func authenticate(phone: String, otp: String, action: AuthAction = .signUp) async throws -> AuthenticateResult {
        AppLog.banner("AUTH · verify OTP")
        AppLog.info(.auth, "phone=+91\(phone) otp=\(otp.count)digits action=\(action.rawValue)")

        let psn = DeviceInfo.prefixedSerialNumber
        let body = AuthenticateBody(
            socketType: "MAIN_CLIENT",
            merchantName: "TEZ_RUMMY",
            DeviceId: psn,
            det: "ios",
            action: action.rawValue,
            SerialNumber: psn,
            ult: "phone",
            lc: DeviceInfo.language,
            languagePreference: DeviceInfo.language,
            isNewSignupFlowEnabled: true,
            av: DeviceInfo.buildVersionCode,
            version_code: DeviceInfo.buildVersionCode,
            anov: DeviceInfo.iOSVersion,
            rfc: "",
            uniqueDeviceId: psn,
            packageName: DeviceInfo.zupeeAppName,
            newauth: true,
            otp: otp,
            signupPhoneNumber: phone,
            gaId: nil,
            isConsultationCampaign: true
        )
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/auth/authenticateUser",
            method: .POST,
            body: body,
            requiresAuth: false
        ), as: AuthenticateResult.self)

        if result.flag == false {
            let serverMessage = result.error ?? result.externalMessage
            AppLog.error(.auth, "authenticate flag=false errorCode=\(result.errorCode ?? "?") error=\(serverMessage ?? "n/a")")
            throw APIError.businessFailure(message: serverMessage ?? "Incorrect OTP. Please try again.")
        }
        guard let token = result.accessToken, !token.isEmpty else {
            AppLog.error(.auth, "authenticate decoded but no accessToken in signUpData. errorCode=\(result.errorCode ?? "?") flag=\(result.flag.map(String.init) ?? "?")")
            throw APIError.businessFailure(message: result.externalMessage ?? result.error ?? "Sign-in failed. Please try again.")
        }
        TokenStore.shared.accessToken = token
        if let refresh = result.refreshToken { TokenStore.shared.refreshToken = refresh }
        if let userId = result.userId { TokenStore.shared.userId = userId }
        if let zupeeUserId = result.zupeeUserId { TokenStore.shared.zupeeUserId = zupeeUserId }
        if let zodiac = result.signUpData?.zodiacName { TokenStore.shared.zodiacName = zodiac }
        TokenStore.shared.mobileNumber = phone

        AppLog.info(.auth, "authenticate success userId=\(result.userId ?? "?") zupeeUserId=\(result.zupeeUserId.map(String.init) ?? "?") tokenLen=\(token.count) refreshLen=\(result.refreshToken?.count ?? 0)")

        return result
    }

    static func logout() {
        AppLog.info(.auth, "logout · clearing keychain")
        TokenStore.shared.clear()
    }
}
