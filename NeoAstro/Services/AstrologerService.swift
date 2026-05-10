import Foundation

enum AstrologerService {
    static func listAll() async throws -> [AstrologerAPI] {
        AppLog.info(.home, "service · listAll")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/listAstrologers",
            method: .GET,
            query: ["consultationEnabled": "true"]
        ), as: AstrologerListResponse.self)
        AppLog.info(.home, "service · listAll items=\(result.totalWidgets) astrologers=\(result.astrologers.count)")
        return result.astrologers
    }

    static func listBest() async throws -> [AstrologerAPI] {
        AppLog.info(.home, "service · listBest")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/listAstrologers",
            method: .GET,
            query: ["consultationEnabled": "true"]
        ), as: AstrologerListResponse.self)
        AppLog.info(.home, "service · listBest items=\(result.totalWidgets) astrologers=\(result.astrologers.count)")
        return result.astrologers
    }

    static func search(query searchQuery: String) async throws -> [AstrologerAPI] {
        AppLog.info(.home, "service · search query='\(searchQuery)'")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/listAstrologers",
            method: .GET,
            query: [
                "consultationEnabled": "true",
                "search": searchQuery
            ]
        ), as: AstrologerListResponse.self)
        return result.astrologers
    }

    /// Detail fetch for a single astrologer — surfaces stories, education,
    /// long-form bio, and rating aggregates that aren't in the list payload.
    struct GetProfileBody: Encodable { let astroId: String }
    static func getProfile(astroId: String) async throws -> AstrologerProfileDetail? {
        AppLog.info(.home, "service · getProfile astroId=\(astroId)")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/getProfile",
            method: .POST,
            body: GetProfileBody(astroId: astroId)
        ), as: AstrologerProfileResponse.self)
        return result.response?.astrologer
    }

    /// Reviews list. Backend may return empty/nil; surface as `[]`.
    static func reviews(astroId: String) async throws -> [AstrologerReview] {
        AppLog.info(.home, "service · reviews astroId=\(astroId)")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/reviews",
            method: .GET,
            query: ["astroId": astroId]
        ), as: AstrologerReviewsResponse.self)
        return result.reviews ?? []
    }

    /// Subscribe the user to a "notify me when online" alert for an
    /// offline astrologer.
    static func notifyMeWhenOnline(astroId: String) async throws {
        AppLog.info(.home, "service · notifyUser astroId=\(astroId)")
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/chat/notifyUser",
            method: .POST,
            body: NotifyUserBody(astroId: astroId)
        ))
    }

    /// Optional popup banner shown on first profile open (e.g. promo offer).
    static func popupDetails(astroId: String) async throws -> AstrologerPopupContent? {
        AppLog.info(.home, "service · popupDetails astroId=\(astroId)")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/getPopupDetails",
            method: .GET,
            query: ["astroId": astroId]
        ), as: AstrologerPopupResponse.self)
        return result.popup
    }

    /// Long-tail metadata (top questions, consultation count, etc.).
    static func metadata(astroId: String) async throws -> AstrologerMetadata? {
        AppLog.info(.home, "service · metadata astroId=\(astroId)")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/astrologer/getAstrologerMetadata",
            method: .GET,
            query: ["astroId": astroId]
        ), as: AstrologerMetadataResponse.self)
        return result.metadata
    }
}
