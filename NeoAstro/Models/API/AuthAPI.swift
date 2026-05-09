import Foundation

struct RequestOTPBody: Encodable {
    let deviceUniqueId: String
    let phoneNumber: String
    let action: String
    let appPackageName: String
    let userResendOtp: Bool
    let isConsultationCampaign: Bool
}

struct AuthenticateBody: Encodable {
    let socketType: String
    let merchantName: String
    let DeviceId: String
    let det: String
    let action: String
    let SerialNumber: String
    let ult: String
    let lc: String
    let languagePreference: String
    let isNewSignupFlowEnabled: Bool
    let av: String
    let version_code: String
    let anov: String
    let rfc: String
    let uniqueDeviceId: String
    let packageName: String
    let newauth: Bool
    let otp: String
    let signupPhoneNumber: String
    let gaId: String?
    let isConsultationCampaign: Bool
}

/// Zupee nests the issued tokens inside `signUpData`. Anything at the top level
/// (success/errorCode/postConfig) is metadata.
struct AuthenticateResult: Decodable {
    let success: Bool?
    let flag: Bool?
    let errorCode: String?
    let externalMessage: String?
    let error: String?
    let signUpData: SignUpData?

    struct SignUpData: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let _id: String?
        let zupeeUserId: Int?
        let zodiacName: String?
        let signupPhoneNumber: String?
        let validity: Double?
        let refreshTokenExpiresAt: Double?
        let isNewSignup: Bool?
        let un: String?
        let ue: String?
        let pp: String?
    }

    var accessToken: String? { signUpData?.accessToken }
    var refreshToken: String? { signUpData?.refreshToken }
    var userId: String? { signUpData?._id }
    var zupeeUserId: Int? { signUpData?.zupeeUserId }
}

struct SimpleSuccess: Decodable { let success: Bool? }
