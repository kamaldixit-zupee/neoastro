import Foundation

enum UserSettingsService {
    struct EmptyBody: Encodable {}

    static func fetch() async throws -> [UserSettingsWidget] {
        AppLog.info(.account, "service · getUserSettings")
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/user/getUserSettings",
            method: .POST,
            body: EmptyBody()
        ), as: UserSettingsResponse.self)
        let widgets = result.widgets ?? []
        AppLog.info(.account, "service · getUserSettings widgets=\(widgets.count) items=\(widgets.flatMap { $0.items ?? [] }.count)")
        return widgets
    }
}
