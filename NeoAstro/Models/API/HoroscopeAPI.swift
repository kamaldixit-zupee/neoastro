import Foundation

struct Horoscope: Decodable {
    let status: String?
    let zuid: Int?
    let zodiacName: String?
    let zodiacSignUrl: String?
    let zodiacBackgroundUrl: String?
    let horoscopeTitle: String?
    let cosmicPositionText: String?
    let luckyEntities: [LuckyEntity]?
    let horoscopeCards: [HoroscopeCard]?
    let chartUrls: [ChartURL]?
    let greetingImageUrl: String?
    let ctaText: String?
    let horoscopeAstrologer: AstrologerAPI?

    var isPending: Bool { (status ?? "").lowercased() == "pending" }

    struct LuckyEntity: Decodable, Hashable {
        let text: String?
        let entity: String?
        let code: String?
    }

    struct HoroscopeCard: Decodable, Hashable {
        let title: String?
        let summary: String?
        let description: [String]?
        let sentiment: String?
        let iconUrl: String?
        let color: String?
    }

    struct ChartURL: Decodable, Hashable {
        let url: String?
        let heading: String?
    }
}

struct HoroscopeRequestBody: Encodable {
    let zodiacSign: String?
    let type: String?
}
