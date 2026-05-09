import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var refreshTask: Task<Void, Error>?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    enum HTTPMethod: String { case GET, POST, PUT, DELETE }

    struct Request {
        var path: String
        var method: APIClient.HTTPMethod = .GET
        var query: [String: String]? = nil
        var body: Encodable? = nil
        var requiresAuth: Bool = true
        var extraHeaders: [String: String] = [:]
    }

    func send<T: Decodable>(_ request: Request, as type: T.Type) async throws -> T {
        do {
            return try await execute(request, as: T.self)
        } catch APIError.unauthorized where request.requiresAuth {
            AppLog.warn(.api, "401 received, refreshing token then retrying \(request.path)")
            try await refreshIfNeeded()
            return try await execute(request, as: T.self)
        }
    }

    func sendVoid(_ request: Request) async throws {
        _ = try await send(request, as: EmptyResponse.self)
    }

    private func execute<T: Decodable>(_ request: Request, as type: T.Type) async throws -> T {
        let urlRequest = try buildURLRequest(request)

        AppLog.info(.api, "→ \(request.method.rawValue) \(urlRequest.url?.absoluteString ?? request.path)")
        if let body = urlRequest.httpBody, let json = String(data: body, encoding: .utf8) {
            AppLog.debug(.api, "   body: \(json)")
        }
        if let headers = urlRequest.allHTTPHeaderFields {
            let safe = headers.mapValues { value -> String in
                if value.count > 30 { return String(value.prefix(20)) + "…(\(value.count) chars)" }
                return value
            }
            AppLog.debug(.api, "   headers: \(safe)")
        }

        let started = Date()
        let (data, response) = try await session.data(for: urlRequest)
        let elapsed = Int(Date().timeIntervalSince(started) * 1000)

        guard let http = response as? HTTPURLResponse else {
            AppLog.error(.api, "← invalid response (not HTTPURLResponse)")
            throw APIError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? "<binary \(data.count) bytes>"
        let preview = bodyString.count > 1500 ? String(bodyString.prefix(1500)) + "…(truncated)" : bodyString
        AppLog.info(.api, "← \(http.statusCode) \(request.path) [\(elapsed)ms] \(data.count)B")
        AppLog.debug(.api, "   response: \(preview)")

        if http.statusCode == 401 { throw APIError.unauthorized }

        guard (200..<300).contains(http.statusCode) else {
            let status = try? decoder.decode(ZupeeStatusEnvelope.self, from: data)
            let message = status?.response?.externalMessage ?? status?.response?.error
            AppLog.error(.api, "server error \(http.statusCode): \(message ?? "no message")")
            throw APIError.server(status: http.statusCode, message: message)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        // Zupee shapes seen in the wild:
        //  A) { en, response: { success, data: T } }            ← typical
        //  B) { en, response: T-with-success-flag }              ← auth: signUpData lives directly under `response`
        //  C) T  (no wrapper)
        // Try each path; surface businessFailure if envelope.success == false.

        if let envelope = try? decoder.decode(ZupeeStatusEnvelope.self, from: data) {
            if envelope.response?.success == false {
                AppLog.error(.api, "business failure: \(envelope.response?.externalMessage ?? envelope.response?.error ?? "unknown")")
                throw APIError.businessFailure(message: envelope.response?.externalMessage ?? envelope.response?.error)
            }
        }

        if let envelope = try? decoder.decode(ZupeeEnvelope<T>.self, from: data),
           let value = envelope.unwrapped {
            AppLog.debug(.api, "decoded via envelope.response.data → \(T.self)")
            return value
        }

        if let wrapped = try? decoder.decode(ResponseOnlyEnvelope<T>.self, from: data),
           let value = wrapped.response {
            AppLog.debug(.api, "decoded via envelope.response → \(T.self)")
            return value
        }

        do {
            let value = try decoder.decode(T.self, from: data)
            AppLog.debug(.api, "decoded directly → \(T.self)")
            return value
        } catch {
            AppLog.error(.api, "decoding failed for \(T.self)", error: error)
            throw APIError.decoding(error)
        }
    }

    private func buildURLRequest(_ request: Request) throws -> URLRequest {
        var components = URLComponents(
            url: APIEnvironment.current.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        )!
        if let query = request.query, !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidResponse }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(DeviceInfo.platform, forHTTPHeaderField: "Platform")
        urlRequest.setValue(DeviceInfo.buildVersionCode, forHTTPHeaderField: "version")
        urlRequest.setValue(DeviceInfo.buildVersionName, forHTTPHeaderField: "appversion")
        urlRequest.setValue(DeviceInfo.zupeeAppName, forHTTPHeaderField: "appname")
        urlRequest.setValue(DeviceInfo.zupeeAppName, forHTTPHeaderField: "packageName")
        urlRequest.setValue(DeviceInfo.language, forHTTPHeaderField: "language")
        urlRequest.setValue(DeviceInfo.prefixedSerialNumber, forHTTPHeaderField: "deviceId")

        if APIEnvironment.current != .prod {
            urlRequest.setValue(APIEnvironment.current.name, forHTTPHeaderField: "x-zupee-env")
        }

        // Zupee sets the raw token (no "Bearer " prefix) on the `authorization` header.
        if request.requiresAuth, let token = TokenStore.shared.accessToken {
            urlRequest.setValue(token, forHTTPHeaderField: "authorization")
            if let userId = TokenStore.shared.userId {
                urlRequest.setValue(userId, forHTTPHeaderField: "ludoUserId")
            }
        }

        for (key, value) in request.extraHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = request.body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return urlRequest
    }

    private func refreshIfNeeded() async throws {
        if let existing = refreshTask {
            try await existing.value
            return
        }
        let task = Task<Void, Error> {
            defer { refreshTask = nil }
            try await refresh()
        }
        refreshTask = task
        try await task.value
    }

    private func refresh() async throws {
        guard let refreshToken = TokenStore.shared.refreshToken else {
            AppLog.warn(.auth, "refresh token missing, clearing session")
            TokenStore.shared.clear()
            throw APIError.unauthorized
        }
        struct Body: Encodable { let refreshToken: String }
        struct Result: Decodable { let accessToken: String?; let refreshToken: String? }

        let urlRequest = try buildURLRequest(.init(
            path: "/v1.0/refreshToken",
            method: .POST,
            body: Body(refreshToken: refreshToken),
            requiresAuth: false
        ))
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            AppLog.error(.auth, "refresh failed, clearing session")
            TokenStore.shared.clear()
            throw APIError.unauthorized
        }
        if let envelope = try? decoder.decode(ZupeeEnvelope<Result>.self, from: data),
           let result = envelope.unwrapped {
            TokenStore.shared.accessToken = result.accessToken ?? TokenStore.shared.accessToken
            TokenStore.shared.refreshToken = result.refreshToken ?? TokenStore.shared.refreshToken
            AppLog.info(.auth, "refresh succeeded")
            return
        }
        if let direct = try? decoder.decode(Result.self, from: data) {
            TokenStore.shared.accessToken = direct.accessToken ?? TokenStore.shared.accessToken
            TokenStore.shared.refreshToken = direct.refreshToken ?? TokenStore.shared.refreshToken
            AppLog.info(.auth, "refresh succeeded (direct)")
            return
        }
        TokenStore.shared.clear()
        AppLog.error(.auth, "refresh response unparseable, clearing session")
        throw APIError.unauthorized
    }
}

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
