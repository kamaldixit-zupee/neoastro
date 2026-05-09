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
}
