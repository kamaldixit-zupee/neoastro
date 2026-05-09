import Foundation

enum PanchangService {
    struct Body: Encodable { let zuid: Int }

    static func today() async throws -> Panchang {
        let zuid = TokenStore.shared.zupeeUserId ?? 0
        AppLog.info(.panchang, "service · today zuid=\(zuid)")
        return try await APIClient.shared.send(.init(
            path: "/v1.0/user/getPanchangDetails",
            method: .POST,
            body: Body(zuid: zuid)
        ), as: Panchang.self)
    }
}
