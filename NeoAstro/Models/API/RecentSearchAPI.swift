import Foundation

struct RecentSearchesResponse: Decodable {
    let astrologerIds: [String]?
}

struct AddRecentSearchBody: Encodable {
    let astroId: String
}

/// `clearRecentSearches` accepts either a specific `astroId` or `clearAll: true`.
struct ClearRecentSearchesBody: Encodable {
    let astroId: String?
    let clearAll: Bool?
}
