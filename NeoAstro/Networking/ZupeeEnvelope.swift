import Foundation

/// `{ en, response: { success, data: T } }`
struct ZupeeEnvelope<T: Decodable>: Decodable {
    let response: ZupeeResponse<T>?
    let en: String?

    var unwrapped: T? { response?.data }
}

struct ZupeeResponse<T: Decodable>: Decodable {
    let success: Bool?
    let data: T?
    let externalMessage: String?
    let error: String?
}

/// `{ en, response: T }` where T already carries the success flag and payload
/// (e.g. authenticateUser puts `signUpData` directly under `response`).
struct ResponseOnlyEnvelope<T: Decodable>: Decodable {
    let response: T?
    let en: String?
}

/// Decoder used purely to inspect `response.success` without committing to a payload type.
struct ZupeeStatusEnvelope: Decodable {
    let response: StatusOnly?

    struct StatusOnly: Decodable {
        let success: Bool?
        let externalMessage: String?
        let error: String?
    }
}

struct EmptyResponse: Decodable {}
