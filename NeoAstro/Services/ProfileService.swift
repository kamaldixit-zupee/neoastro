import Foundation

// MARK: - DTOs local to ProfileService

struct RejoinInfo: Decodable {
    let canRejoin: Bool?
    let message: String?
    let validUntilTimestamp: Double?
}

struct UpdateExperienceBody: Encodable {
    let userExperience: String  // e.g. "BEGINNER" | "INTERMEDIATE" | "ADVANCED"
}

struct UpdateGAIdBody: Encodable {
    let gaId: String
}

struct SetUserLocationBody: Encodable {
    let latitude: Double?
    let longitude: Double?
    let city: String?
    let state: String?
    let country: String?
}

struct ProfilePicPresignedRequest: Encodable {
    let contentType: String
    let fileName: String
}

struct ProfilePicPresignedResponse: Decodable {
    let presignedUrl: String?
    let fileUrl: String?
}

// MARK: - ProfileService

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

    // MARK: - Profile picture upload (2-step presigned URL)

    /// Two-step upload: hit the backend for a presigned URL, then PUT raw
    /// bytes to S3, then patch the profile with the resulting public URL.
    /// `imageData` is the JPEG/PNG bytes; `mimeType` is e.g. `"image/jpeg"`.
    static func uploadProfilePic(imageData: Data, mimeType: String = "image/jpeg") async throws -> URL {
        AppLog.info(.account, "→ uploadProfilePic bytes=\(imageData.count) mime=\(mimeType)")
        // Step 1: ask backend for a presigned URL.
        let presigned = try await APIClient.shared.send(.init(
            path: "/v1.0/user/uploadProfilePic",
            method: .POST,
            body: ProfilePicPresignedRequest(
                contentType: mimeType,
                fileName: "profile_\(Int(Date().timeIntervalSince1970)).jpg"
            )
        ), as: ProfilePicPresignedResponse.self)

        guard
            let presignedString = presigned.presignedUrl,
            let presignedURL = URL(string: presignedString),
            let fileString = presigned.fileUrl,
            let publicURL = URL(string: fileString)
        else {
            throw APIError.businessFailure(message: "Could not get presigned URL")
        }

        // Step 2: PUT bytes to S3.
        var put = URLRequest(url: presignedURL)
        put.httpMethod = "PUT"
        put.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        put.httpBody = imageData
        let (_, response) = try await URLSession.shared.data(for: put)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.server(status: http.statusCode, message: "Upload failed")
        }

        // Step 3: patch the user profile with the resulting URL.
        try await submit(EditProfilePayload(
            name: nil, email: nil, dateOfBirth: nil,
            gender: nil, city: nil, state: nil,
            profilePictureUrl: publicURL.absoluteString
        ))
        AppLog.info(.account, "← uploadProfilePic ok url=\(publicURL.absoluteString)")
        return publicURL
    }

    // MARK: - Misc profile endpoints

    static func setUserLocation(latitude: Double?, longitude: Double?, city: String?, state: String?, country: String?) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/setUserLocation",
            method: .POST,
            body: SetUserLocationBody(
                latitude: latitude,
                longitude: longitude,
                city: city,
                state: state,
                country: country
            )
        ))
    }

    static func updateUserExperience(_ experience: String) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/userExperience/updateUserExperience",
            method: .POST,
            body: UpdateExperienceBody(userExperience: experience)
        ))
    }

    static func updateGAId(_ id: String) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/user/updateGAId",
            method: .POST,
            body: UpdateGAIdBody(gaId: id)
        ))
    }

    static func getRejoinInfo() async throws -> RejoinInfo {
        struct EmptyBody: Encodable {}
        return try await APIClient.shared.send(.init(
            path: "/v1.0/user/getRejoinInfo",
            method: .POST,
            body: EmptyBody()
        ), as: RejoinInfo.self)
    }
}
