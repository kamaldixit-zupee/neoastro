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
