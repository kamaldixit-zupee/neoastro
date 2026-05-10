import Foundation
import SocketIO

/// Single owner of the Socket.IO client. Built as an actor so handler
/// callbacks and emit calls serialise cleanly without an explicit lock.
///
/// Lifecycle:
///   1. App boot post-auth → `connect()`.
///   2. Server validates the JWT in handshake. On `CONNECTION_AUTHENTICATED`,
///      `RealtimeStore` flips `isConnected = true`.
///   3. Network drop or app foreground → `connect()` again (idempotent).
///   4. On 401-equivalent error codes (256/257) → `AuthService.logout()`.
///
/// Reconnection: we disable Socket.IO's built-in retry (`reconnects: false`)
/// and drive retries manually via `ReconnectionPolicy` so this matches the
/// RN behavior exactly.
actor NeoAstroSocket {
    static let shared = NeoAstroSocket()

    // MARK: - State

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt: Int = 0
    private let policy = ReconnectionPolicy()

    /// Continuation that fans events out to whoever subscribes.
    /// Constructed lazily via `events`.
    private var continuations: [UUID: AsyncStream<RealtimeEvent>.Continuation] = [:]

    // MARK: - Public

    struct RealtimeEvent {
        let event: SocketEvent
        let envelope: SocketEnvelopeIn
    }

    /// Multi-subscriber event stream. Each call returns a fresh `AsyncStream`
    /// that yields every server→client event after subscription.
    func events() -> AsyncStream<RealtimeEvent> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }

    /// Open (or reuse) the connection. Idempotent — calling while already
    /// connected is a no-op.
    func connect() {
        guard TokenStore.shared.isAuthenticated else {
            AppLog.warn(.socketIO, "connect skipped: no token (status=\(statusString))")
            return
        }
        if socket?.status == .connected || socket?.status == .connecting {
            AppLog.info(.socketIO, "connect skipped: already \(statusString)")
            return
        }

        let baseURL = APIEnvironment.current.baseURL
        let query = handshakeQuery()

        AppLog.info(.socketIO, "connecting host=\(baseURL.absoluteString) status=\(statusString)")
        AppLog.debug(.socketIO, "handshake query=\(redactedQuery(query))")

        let manager = SocketManager(
            socketURL: baseURL,
            config: [
                .compress,
                .forceWebsockets(true),
                .reconnects(false),
                .version(.two), // engine.io v3 wire protocol
                .connectParams(query),
                .extraHeaders(handshakeHeaders())
            ]
        )

        let client = manager.defaultSocket
        client.on(clientEvent: .connect) { [weak self] _, _ in
            Task { await self?.handleConnect() }
        }
        client.on(clientEvent: .disconnect) { [weak self] _, _ in
            Task { await self?.handleDisconnect() }
        }
        client.on(clientEvent: .error) { [weak self] data, _ in
            Task { await self?.handleError(data) }
        }
        client.on(SocketChannel.response) { [weak self] data, _ in
            Task { await self?.handleResponse(data) }
        }

        self.manager = manager
        self.socket = client
        client.connect()
    }

    /// Tear down completely. Called on logout.
    func disconnect() {
        AppLog.info(.socketIO, "disconnect requested status=\(statusString)")
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempt = 0
        socket?.disconnect()
        socket = nil
        manager?.disconnect()
        manager = nil
    }

    /// Marker payload used by `emit(_:)` for fire-and-forget events that
    /// don't carry data (e.g. analytics signals).
    struct EmptyPayload: Encodable {}

    /// No-payload convenience.
    func emit(_ event: SocketEvent) {
        let none: EmptyPayload? = nil
        emit(event, payload: none)
    }

    /// Emit a typed payload via the `req` channel.
    ///
    /// Wire format: the server's `requestHandler` does `JSON.parse(requestString)`
    /// on whatever arrives, so we must send the envelope as a JSON-encoded
    /// **string**, not a dictionary. RN does the same via
    /// `socket.emit("req", JSON.stringify({en, data}))`. Sending a dict
    /// instead silently fails on the server (parse throws, swallowed by
    /// try/catch, no response).
    func emit<P: Encodable>(_ event: SocketEvent, payload: P? = nil) {
        guard let socket, socket.status == .connected else {
            AppLog.warn(.socketIO, "emit dropped (status=\(statusString)) event=\(event.rawValue)")
            return
        }
        do {
            let json = try encodeEnvelope(event: event, payload: payload)
            AppLog.debug(.socketIO, "emit → \(event.rawValue) status=\(statusString) bytes=\(json.utf8.count)")
            socket.emit(SocketChannel.request, json)
        } catch {
            AppLog.error(.socketIO, "emit failed event=\(event.rawValue)", error: error)
        }
    }

    /// Emit + wait for an ack with a typed retry policy. Used for messages
    /// that must not silently drop (e.g. RAISE_QUERY).
    func emitWithAck<P: Encodable>(
        _ event: SocketEvent,
        payload: P,
        timeoutSeconds: Double = 2.0,
        maxRetries: Int = 3
    ) async -> Bool {
        guard let socket else { return false }
        do {
            let json = try encodeEnvelope(event: event, payload: payload)

            for attempt in 0...maxRetries {
                let ack = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                    socket.emitWithAck(SocketChannel.request, json).timingOut(after: timeoutSeconds) { _ in
                        cont.resume(returning: true)
                    }
                }
                if ack { return true }
                let backoff = Double(attempt + 1) * 2.0
                AppLog.warn(.socketIO, "ack timeout event=\(event.rawValue) status=\(statusString) attempt=\(attempt) retryIn=\(backoff)s")
                try? await Task.sleep(for: .seconds(backoff))
            }
            return false
        } catch {
            AppLog.error(.socketIO, "emitWithAck failed event=\(event.rawValue)", error: error)
            return false
        }
    }

    /// Encode `{en, data}` to a JSON string for the `req` channel.
    private func encodeEnvelope<P: Encodable>(event: SocketEvent, payload: P?) throws -> String {
        let envelope = SocketEnvelopeOut(en: event.rawValue, data: payload)
        let data = try JSONEncoder().encode(envelope)
        guard let json = String(data: data, encoding: .utf8) else {
            throw APIError.businessFailure(message: "envelope encode failed")
        }
        return json
    }

    // MARK: - Handshake

    /// Mirrors zupee-rn-astro's `getSpEventData` (`src/socket/utils.ts`)
    /// key-for-key. The RN handshake is the only known-working shape — the
    /// server's `connection` handler is gated on `reauth`+`authenticateWithRestApi`
    /// to run `CONNECTION_AUTHENTICATED` (which fills `client.uid`,
    /// `client.zupeeUserId` and writes the Redis socket-cache used by
    /// `SendDirect`); `signupPhoneNumber`+`ult: "phone"` are read by
    /// `setUserLoginTypeAndEmail`. Drift here = silent server-side drops.
    private func handshakeQuery() -> [String: String] {
        let token = TokenStore.shared.accessToken ?? ""
        let refresh = TokenStore.shared.refreshToken ?? ""
        let phone = TokenStore.shared.mobileNumber ?? ""
        let email = TokenStore.shared.userEmail ?? ""
        let name = TokenStore.shared.userName ?? ""
        let lang = DeviceInfo.language
        let psn = DeviceInfo.prefixedSerialNumber
        let buildCode = DeviceInfo.buildVersionCode
        // RN's `Platform.Version` on iOS is the major iOS version as a string
        // (e.g. "26"). The server doesn't strictly validate this, but match
        // RN's shape so logs line up.
        let iosMajor = DeviceInfo.iOSVersion.split(separator: ".").first.map(String.init) ?? DeviceInfo.iOSVersion
        let connectionInfo = #"{"networkType":"wifi","isConnected":true}"#
        return [
            "socketType": "MAIN_CLIENT",
            "action": "SignIn",
            "rfc": "",
            "av": buildCode,
            "iv": buildCode,
            "app_version": DeviceInfo.buildVersionName,
            "version_code": buildCode,
            "packageName": DeviceInfo.zupeeAppName,
            "anov": iosMajor,
            "det": DeviceInfo.platform,
            "deviceType": DeviceInfo.platform,
            "lc": lang,
            "languagePreference": lang,
            "DeviceId": "",
            "accessToken": token,
            "signupPhoneNumber": phone,
            "refreshToken": refresh,
            "ue": email,
            "un": name,
            "ult": "phone",
            "reauth": "true",
            "authenticateWithRestApi": "true",
            "uniqueDeviceId": psn,
            "SerialNumber": psn,
            "connectionInfo": connectionInfo
        ]
    }

    private func handshakeHeaders() -> [String: String] {
        ["x-zupee-env": APIEnvironment.current.name]
    }

    // MARK: - Lifecycle handlers

    private func handleConnect() {
        AppLog.info(.socketIO, "connected status=\(statusString)")
        reconnectAttempt = 0
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    private func handleDisconnect() {
        AppLog.warn(.socketIO, "disconnected status=\(statusString) — scheduling reconnect")
        scheduleReconnect()
    }

    private func handleError(_ data: [Any]) {
        AppLog.error(.socketIO, "error status=\(statusString) data=\(data)")
        scheduleReconnect()
    }

    private func handleResponse(_ data: [Any]) {
        guard let first = data.first, let envelope = SocketEnvelopeIn(any: first) else {
            AppLog.warn(.socketIO, "response unparseable raw=\(data)")
            return
        }
        guard let event = SocketEvent(rawValue: envelope.en) else {
            AppLog.debug(.socketIO, "response unhandled event=\(envelope.en)")
            return
        }
        AppLog.info(.socketIO, "← \(event.rawValue)")
        let realtimeEvent = RealtimeEvent(event: event, envelope: envelope)
        for cont in continuations.values { cont.yield(realtimeEvent) }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { [policy] in
            while !Task.isCancelled {
                guard let delay = policy.delay(forAttempt: reconnectAttempt) else {
                    AppLog.error(.socketIO, "reconnect attempts exhausted status=\(statusString)")
                    return
                }
                AppLog.info(.socketIO, "reconnect attempt=\(reconnectAttempt) in=\(delay) status=\(statusString)")
                try? await Task.sleep(for: delay)
                reconnectAttempt += 1
                connect()
                if socket?.status == .connected {
                    return
                }
            }
        }
    }

    // MARK: - Logging helpers

    /// Human-readable Socket.IO status for logs.
    private var statusString: String {
        guard let socket else { return "no-socket" }
        switch socket.status {
        case .connected: return "connected"
        case .connecting: return "connecting"
        case .disconnected: return "disconnected"
        case .notConnected: return "notConnected"
        @unknown default: return "unknown"
        }
    }

    /// Token fields are short-formed so the handshake query can be safely
    /// printed at debug level without leaking the full JWTs.
    private func redactedQuery(_ q: [String: String]) -> [String: String] {
        var copy = q
        for k in ["accessToken", "refreshToken"] {
            if let v = copy[k], !v.isEmpty {
                copy[k] = "<set len=\(v.count)>"
            } else {
                copy[k] = "<empty>"
            }
        }
        return copy
    }
}
