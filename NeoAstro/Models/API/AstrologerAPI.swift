import Foundation

struct AstrologerAPI: Decodable, Identifiable, Hashable {
    let _id: String
    let name: String
    let image: String?
    let images: AstrologerImages?
    let description: String?
    let bio: String?
    let price: Double?
    let discountedPrice: Double?
    let experience: Double?
    let languages: [String]?
    let ratings: Double?
    let verified: Bool?
    let chats: Int?
    let totalMins: Int?
    let studies: [String]?
    let isActive: Bool?
    let premium: Bool?
    let heading: String?
    let subHeading: String?
    let location: String?
    let qualification: String?
    let qualificationText: String?
    let experienceText: String?
    let trustText: String?
    let status: AstrologerStatus?

    var id: String { _id }

    var displayPrice: Int { Int(discountedPrice ?? price ?? 0) }
    var originalPrice: Int? {
        guard let price, let discountedPrice, discountedPrice < price else { return nil }
        return Int(price)
    }

    var imageURL: URL? {
        if let original = images?.original, let url = URL(string: original) { return url }
        if let image, let url = URL(string: image) { return url }
        return nil
    }

    struct AstrologerImages: Decodable, Hashable {
        let original: String?
        let avatar: String?
    }

    struct AstrologerStatus: Decodable, Hashable {
        let text: String?
        let state: String?
    }
}

// MARK: - Profile detail (POST /v1.0/astrologer/getProfile)

struct AstrologerProfileResponse: Decodable {
    let response: AstrologerProfileData?
}

struct AstrologerProfileData: Decodable {
    let astrologer: AstrologerProfileDetail?
}

struct AstrologerProfileDetail: Decodable {
    let _id: String?
    let stories: [AstrologerStory]?
    let educationAndCertifications: [AstrologerEducation]?
    let bio: String?
    let totalRatings: Int?
    let totalReviews: Int?
    let onlineSince: String?
}

struct AstrologerStory: Decodable, Identifiable, Hashable {
    let _id: String?
    let imageUrl: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    let caption: String?
    let createdAt: Double?

    var id: String { _id ?? imageUrl ?? videoUrl ?? UUID().uuidString }

    var mediaURL: URL? {
        if let v = videoUrl, !v.isEmpty { return URL(string: v) }
        if let i = imageUrl, !i.isEmpty { return URL(string: i) }
        return nil
    }
    var thumbURL: URL? {
        thumbnailUrl.flatMap(URL.init(string:))
            ?? imageUrl.flatMap(URL.init(string:))
    }
    var isVideo: Bool { videoUrl != nil && !(videoUrl?.isEmpty ?? true) }
}

struct AstrologerEducation: Decodable, Identifiable, Hashable {
    let _id: String?
    let title: String?
    let institution: String?
    let year: String?
    let iconUrl: String?

    var id: String { _id ?? "\(title ?? "")_\(institution ?? "")" }
}

// MARK: - Reviews (GET /v1.0/astrologer/reviews)

struct AstrologerReviewsResponse: Decodable {
    let reviews: [AstrologerReview]?
    let total: Int?
    let averageRating: Double?
}

struct AstrologerReview: Decodable, Identifiable, Hashable {
    let _id: String?
    let userName: String?
    let userImage: String?
    let rating: Double?
    let comment: String?
    let createdAt: Double?

    var id: String { _id ?? UUID().uuidString }
    var date: Date {
        guard let ts = createdAt else { return .now }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }
    var displayName: String { userName ?? "User" }
    var displayRating: Int { Int((rating ?? 0).rounded()) }
}

// MARK: - Notify me

struct NotifyUserBody: Encodable {
    let astroId: String
}

// MARK: - Popup details (GET /v1.0/astrologer/getPopupDetails)

struct AstrologerPopupResponse: Decodable {
    let popup: AstrologerPopupContent?
}

struct AstrologerPopupContent: Decodable, Hashable {
    let title: String?
    let subtitle: String?
    let imageUrl: String?
    let ctaText: String?
    let ctaValue: String?
}

// MARK: - Metadata (GET /v1.0/astrologer/getAstrologerMetadata)

struct AstrologerMetadataResponse: Decodable {
    let metadata: AstrologerMetadata?
}

struct AstrologerMetadata: Decodable, Hashable {
    let totalChats: Int?
    let totalMinutes: Int?
    let yearsActive: Int?
    let speciality: String?
    let topQuestions: [String]?
    let consultationCount: Int?
}

// MARK: - List response (existing)

struct AstrologerListResponse: Decodable {
    let astrologers: [AstrologerAPI]
    let totalWidgets: Int

    private enum CodingKeys: String, CodingKey { case data }
    private enum WidgetKeys: String, CodingKey { case type, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard c.contains(.data) else {
            self.astrologers = []
            self.totalWidgets = 0
            return
        }

        var nested = try c.nestedUnkeyedContainer(forKey: .data)
        var collected: [AstrologerAPI] = []
        var total = 0

        while !nested.isAtEnd {
            total += 1
            if try nested.decodeNil() { continue }
            // Each widget is `{ type, data, ... }`. We only want ASTRO_CARD widgets.
            if let widget = try? nested.nestedContainer(keyedBy: WidgetKeys.self) {
                let type = try? widget.decodeIfPresent(String.self, forKey: .type)
                if type == "ASTRO_CARD",
                   let astro = try? widget.decode(AstrologerAPI.self, forKey: .data) {
                    collected.append(astro)
                }
            } else {
                _ = try? nested.decode(AnyJSON.self)
            }
        }

        self.astrologers = collected
        self.totalWidgets = total
    }

    private struct AnyJSON: Decodable {}
}
