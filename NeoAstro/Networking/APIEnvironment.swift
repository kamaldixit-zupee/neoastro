import Foundation

enum APIEnvironment {
    case stage
    case prod

    static let current: APIEnvironment = .stage

    var baseURL: URL {
        switch self {
        case .stage: URL(string: "https://cse-sna-superapp-service.neoastrojoy.com")!
        case .prod:  URL(string: "https://api.neoastro.com")!
        }
    }

    var name: String {
        switch self {
        case .stage: "cse"
        case .prod:  "prod"
        }
    }
}
