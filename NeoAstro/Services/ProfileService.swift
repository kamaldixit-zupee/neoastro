import Foundation

enum ProfileService {
    struct ViewProfileBody: Encodable {
        let zupeeUserId: Int
    }

    static func viewProfile() async throws -> UserDetails {
        guard let zupeeUserId = TokenStore.shared.zupeeUserId else { throw APIError.unauthorized }
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/profile/viewProfile",
            method: .POST,
            body: ViewProfileBody(zupeeUserId: zupeeUserId)
        ), as: ViewProfileResponse.self)
        if let zodiac = result.userDetail?.zodiacName {
            TokenStore.shared.zodiacName = zodiac
        }
        guard let userDetail = result.userDetail else {
            throw APIError.businessFailure(message: "Profile not available")
        }
        return userDetail
    }

    static func getUserDetails() async throws -> UserDetails {
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/user/getUserDetails",
            method: .GET
        ), as: ViewProfileResponse.self)
        guard let userDetail = result.userDetail else {
            throw APIError.businessFailure(message: "Profile not available")
        }
        return userDetail
    }

    static func submit(_ payload: EditProfilePayload) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/profile/submit",
            method: .POST,
            body: payload
        ))
    }

    static func deleteAccount() async throws {
        struct EmptyBody: Encodable {}
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/deleteUserAccount",
            method: .POST,
            body: EmptyBody()
        ))
    }
}
