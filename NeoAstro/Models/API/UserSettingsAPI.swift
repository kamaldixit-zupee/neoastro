import Foundation

struct UserSettingsResponse: Decodable {
    let success: Bool?
    let widgets: [UserSettingsWidget]?

    private enum CodingKeys: String, CodingKey { case success, widgets }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.success = try c.decodeIfPresent(Bool.self, forKey: .success)

        // The server sometimes sends `null` entries in the widgets array. Decode
        // each entry leniently and discard the nulls + anything that fails to
        // parse, so a single bad widget doesn't kill the whole list.
        if c.contains(.widgets) {
            var nested = try c.nestedUnkeyedContainer(forKey: .widgets)
            var collected: [UserSettingsWidget] = []
            while !nested.isAtEnd {
                if try nested.decodeNil() { continue }
                if let widget = try? nested.decode(UserSettingsWidget.self) {
                    collected.append(widget)
                } else {
                    _ = try? nested.decode(AnyJSON.self)
                }
            }
            self.widgets = collected
        } else {
            self.widgets = nil
        }
    }

    private struct AnyJSON: Decodable {}
}

struct UserSettingsWidget: Decodable, Identifiable {
    let widgetType: String?
    let items: [UserSettingsItem]?
    let style: WidgetStyle?

    let id = UUID()

    private enum CodingKeys: String, CodingKey { case widgetType, items, style }

    struct WidgetStyle: Decodable, Hashable {
        let navigationIconVisible: Bool?
    }
}

struct UserSettingsItem: Decodable, Identifiable {
    let id: String?
    let username: String?
    let imageUrl: String?
    let title: String?
    let subTitle: String?
    let description: String?
    let tertiaryTitle: String?
    let hidden: Bool?
    let selected: String?
    let cta: UserSettingsCTA?
    let options: UserSettingsOptions?

    var resolvedId: String { id ?? UUID().uuidString }
    var isVisible: Bool { hidden != true }

    var iconURL: URL? {
        guard let imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) else { return nil }
        return url
    }

    var stableID: String { resolvedId + (title ?? "") + (subTitle ?? "") }
}

struct UserSettingsCTA: Decodable, Hashable {
    let type: String?
    let value: String?
    let displayText: String?
    let link: String?
    let data: CTAData?

    struct CTAData: Decodable, Hashable {
        let screenTitle: String?
        let showAppVersion: Bool?
        let items: [CTASubItem]?
    }

    struct CTASubItem: Decodable, Hashable {
        let displayText: String?
        let type: String?
        let value: String?
    }
}

struct UserSettingsOptions: Decodable, Hashable {
    let enable: String?
    let disable: String?
    let en: String?
    let hi: String?
}
