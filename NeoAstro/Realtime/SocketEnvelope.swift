import Foundation

/// Wire envelope used by every event:
///
///     client→server :  socket.emit("req", { en: "<EVENT>", data: <payload> })
///     server→client :  socket.emit("res", { en: "<EVENT>", data: <payload> })
///
/// The backend uses the named keys `req` / `res` rather than per-event names,
/// so we always subscribe to those two and dispatch internally on `en`.
enum SocketChannel {
    static let request  = "req"
    static let response = "res"
}

/// Helper for round-tripping the inner `{ en, data }` shape.
///
/// `data` is held as raw `Data` (already JSON-serialised) so each handler
/// can decode it into its own typed payload. Storing as `[String: Any]` would
/// bake in `JSONSerialization` semantics and make codable round-trips lossy.
struct SocketEnvelopeOut: Encodable {
    let en: String
    let data: Encodable?

    enum CodingKeys: String, CodingKey { case en, data }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(en, forKey: .en)
        if let data {
            try container.encode(AnyEncodable(data), forKey: .data)
        }
    }
}

/// Inbound envelope. We accept `data` as either a JSON object or absent and
/// re-serialise it so handlers can decode their own typed shape.
struct SocketEnvelopeIn {
    let en: String
    let data: Data?

    /// Build from the loosely-typed dictionary that Socket.IO Swift hands us.
    init?(any value: Any) {
        guard let dict = value as? [String: Any],
              let en = dict["en"] as? String else { return nil }
        self.en = en
        if let inner = dict["data"] {
            self.data = try? JSONSerialization.data(withJSONObject: inner, options: [.fragmentsAllowed])
        } else {
            self.data = nil
        }
    }

    /// Decode the inner `data` into a typed payload. Returns `nil` if `data`
    /// was absent or shape didn't match.
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - AnyEncodable

/// Type-erased `Encodable` so `SocketEnvelopeOut.data` can carry any payload
/// without making the envelope generic.
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) {
        self._encode = value.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
