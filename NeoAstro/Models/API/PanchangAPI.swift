import Foundation

struct Panchang: Decodable {
    let location: String?
    let screenTitle: String?
    let screenSubTitle: String?
    let widgets: [PanchangWidget]?
    let cta: PanchangCTA?
}

struct PanchangCTA: Decodable, Hashable {
    let displayText: String?
    let type: String?
    let value: String?
}

struct PanchangTimePoint: Decodable, Hashable {
    let displayText: String?
    let timeMs: Double?
}

struct PanchangRiseSet: Decodable, Hashable {
    let iconUrl: String?
    let title: String?
    let time: PanchangTimePoint?
}

struct PanchangTithi: Decodable, Hashable {
    let tithiName: String?
    let summary: String?
    let endTime: PanchangTimePoint?
}

struct PanchangKaalItem: Decodable, Hashable, Identifiable {
    let name: String?
    let startTime: PanchangTimePoint?
    let endTime: PanchangTimePoint?
    let iconUrl: String?
    let styles: KaalStyles?
    var id: String { (name ?? "") + (startTime?.displayText ?? "") }

    struct KaalStyles: Decodable, Hashable {
        let backgroundColor: String?
        let segmentColor: String?
    }
}

struct PanchangChaughadiyaDay: Decodable, Hashable, Identifiable {
    let title: String?
    let type: String?
    let startTime: PanchangTimePoint?
    var id: String { (title ?? "") + (startTime?.displayText ?? "") }
}

struct PanchangNakshatraItem: Decodable, Hashable, Identifiable {
    let isTitle: Bool?
    let tag: NakshatraTag?
    let endTime: PanchangTimePoint?
    let summary: String?
    let title: String?
    let infoType: String?
    let iconUrl: String?

    var id: String { (title ?? "") + (infoType ?? "") + (endTime?.displayText ?? "") }

    struct NakshatraTag: Decodable, Hashable {
        let iconUrl: String?
        let name: String?
    }
}

/// Tagged union — the API sends `widget_type` to discriminate.
enum PanchangWidget: Decodable, Identifiable {
    case hero(Hero)
    case sunMoon(SunMoon)
    case kaal(Kaal)
    case chaughadiya(Chaughadiya)
    case nakshatra(Nakshatra)
    case unknown(String)

    var id: String {
        switch self {
        case .hero: "HERO"
        case .sunMoon: "SUN_MOON"
        case .kaal: "KAAL"
        case .chaughadiya: "CHAUGHADIYA"
        case .nakshatra: "NAKSHATRA"
        case .unknown(let t): "UNKNOWN_\(t)"
        }
    }

    private enum CodingKeys: String, CodingKey { case widget_type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = (try? c.decode(String.self, forKey: .widget_type)) ?? ""
        switch type {
        case "HERO":         self = .hero(try Hero(from: decoder))
        case "SUN_MOON":     self = .sunMoon(try SunMoon(from: decoder))
        case "KAAL":         self = .kaal(try Kaal(from: decoder))
        case "CHAUGHADIYA":  self = .chaughadiya(try Chaughadiya(from: decoder))
        case "NAKSHATRA":    self = .nakshatra(try Nakshatra(from: decoder))
        default:             self = .unknown(type)
        }
    }

    struct Hero: Decodable {
        let bgImageUrl: String?
        let gifUrl: String?
        let moonFaceUrl: String?
        let paksha: String?
        let tithi: PanchangTithi?
    }

    struct SunMoon: Decodable {
        let sunrise: PanchangRiseSet?
        let sunset: PanchangRiseSet?
        let moonrise: PanchangRiseSet?
        let moonset: PanchangRiseSet?
    }

    struct Kaal: Decodable {
        let items: [PanchangKaalItem]?
    }

    struct Chaughadiya: Decodable {
        let title: String?
        let subTitle: String?
        let startTime: PanchangTimePoint?
        let day: [PanchangChaughadiyaDay]?
    }

    struct Nakshatra: Decodable {
        let items: [PanchangNakshatraItem]?
    }
}
