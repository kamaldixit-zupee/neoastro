import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)
    case businessFailure(message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Invalid response from server."
        case .unauthorized: "Session expired. Please log in again."
        case .server(let status, let message):
            message ?? "Server error (\(status))."
        case .decoding: "Couldn't read the server response."
        case .transport(let err): err.localizedDescription
        case .businessFailure(let message):
            message ?? "Something went wrong. Please try again."
        }
    }
}
