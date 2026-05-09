import Foundation

enum HoroscopeService {
    enum HoroscopeType: String, CaseIterable, Identifiable {
        case daily, weekly, monthly
        var id: String { rawValue }
        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            case .monthly: "Monthly"
            }
        }
    }

    /// Mirrors zupee's `requestApiPost(GET_HOROSCOPE, {})` — sends an empty body.
    /// The backend infers the user's zodiac from the auth token / signup data.
    static func fetch(sign: String? = nil, type: HoroscopeType = .daily) async throws -> Horoscope {
        struct EmptyBody: Encodable {}

        for attempt in 0..<7 {
            AppLog.info(.horoscope, "service · fetch attempt=\(attempt + 1)")
            let result = try await APIClient.shared.send(.init(
                path: "/v1.0/chat/getHoroscope",
                method: .POST,
                body: EmptyBody()
            ), as: Horoscope.self)

            if !result.isPending {
                if let zodiac = result.zodiacName { TokenStore.shared.zodiacName = zodiac }
                return result
            }
            if attempt < 6 { try await Task.sleep(for: .seconds(5)) }
        }
        throw APIError.businessFailure(message: "Horoscope is still being prepared. Try again in a moment.")
    }
}
