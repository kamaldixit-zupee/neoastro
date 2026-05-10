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
            AppLog.warn(.api, "socket connect skipped: no token")
            return
        }
        if socket?.status == .connected || socket?.status == .connecting {
            return
        }

        let baseURL = APIEnvironment.current.baseURL
        let query = handshakeQuery()

        AppLog.info(.api, "socket connecting host=\(baseURL.absoluteString) keys=\(query.keys.sorted())")

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
        AppLog.info(.api, "socket disconnect requested")
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
    func emit<P: Encodable>(_ event: SocketEvent, payload: P? = nil) {
        guard let socket, socket.status == .connected else {
            AppLog.warn(.api, "socket emit dropped (not connected) event=\(event.rawValue)")
            return
        }
        do {
            let envelope = SocketEnvelopeOut(en: event.rawValue, data: payload)
            let data = try JSONEncoder().encode(envelope)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw APIError.businessFailure(message: "envelope encode failed")
            }
            AppLog.debug(.api, "socket emit \(event.rawValue) keys=\(dict.keys.sorted())")
            socket.emit(SocketChannel.request, dict)
        } catch {
            AppLog.error(.api, "socket emit failed event=\(event.rawValue)", error: error)
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
            let envelope = SocketEnvelopeOut(en: event.rawValue, data: payload)
            let data = try JSONEncoder().encode(envelope)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return false
            }

            for attempt in 0...maxRetries {
                let ack = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                    socket.emitWithAck(SocketChannel.request, dict).timingOut(after: timeoutSeconds) { _ in
                        cont.resume(returning: true)
                    }
                }
                if ack { return true }
                let backoff = Double(attempt + 1) * 2.0
                AppLog.warn(.api, "ack timeout event=\(event.rawValue) attempt=\(attempt) retryIn=\(backoff)s")
                try? await Task.sleep(for: .seconds(backoff))
            }
            return false
        } catch {
            AppLog.error(.api, "emitWithAck failed event=\(event.rawValue)", error: error)
            return false
        }
    }

    // MARK: - Handshake

    private func handshakeQuery() -> [String: String] {
        let token = TokenStore.shared.accessToken ?? ""
        let refresh = TokenStore.shared.refreshToken ?? ""
        let zuid = TokenStore.shared.zupeeUserId.map(String.init) ?? ""
        return [
            "socketType": "MAIN_CLIENT",
            "action": "SIGN_IN_ACTION",
            "accessToken": token,
            "refreshToken": refresh,
            "ult": DeviceInfo.language,
            "uniqueDeviceId": DeviceInfo.prefixedSerialNumber,
            "SerialNumber": DeviceInfo.prefixedSerialNumber,
            "packageName": DeviceInfo.zupeeAppName,
            "appname": DeviceInfo.zupeeAppName,
            "appversion": DeviceInfo.buildVersionCode,
            "appVersionName": DeviceInfo.buildVersionName,
            "version_code": DeviceInfo.buildVersionCode,
            "anov": DeviceInfo.iOSVersion,
            "det": DeviceInfo.platform,
            "deviceType": DeviceInfo.platform,
            "Platform": DeviceInfo.platform,
            "lc": DeviceInfo.language,
            "languagePreference": DeviceInfo.language,
            "ludoUserId": TokenStore.shared.userId ?? "",
            "zuid": zuid
        ]
    }

    private func handshakeHeaders() -> [String: String] {
        ["x-zupee-env": APIEnvironment.current.name]
    }

    // MARK: - Lifecycle handlers

    private func handleConnect() {
        AppLog.info(.api, "socket connected")
        reconnectAttempt = 0
        reconnectTask?.cancel()
        reconnectTask = nil
    }

    private func handleDisconnect() {
        AppLog.warn(.api, "socket disconnected — scheduling reconnect")
        scheduleReconnect()
    }

    private func handleError(_ data: [Any]) {
        AppLog.error(.api, "socket error data=\(data)")
        scheduleReconnect()
    }

    private func handleResponse(_ data: [Any]) {
        guard let first = data.first, let envelope = SocketEnvelopeIn(any: first) else {
            AppLog.warn(.api, "socket response unparseable raw=\(data)")
            return
        }
        guard let event = SocketEvent(rawValue: envelope.en) else {
            AppLog.debug(.api, "socket response unhandled event=\(envelope.en)")
            return
        }
        AppLog.info(.api, "socket ← \(event.rawValue)")
        let realtimeEvent = RealtimeEvent(event: event, envelope: envelope)
        for cont in continuations.values { cont.yield(realtimeEvent) }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { [policy] in
            while !Task.isCancelled {
                guard let delay = policy.delay(forAttempt: reconnectAttempt) else {
                    AppLog.error(.api, "socket reconnect attempts exhausted")
                    return
                }
                AppLog.info(.api, "socket reconnect attempt=\(reconnectAttempt) in=\(delay)")
                try? await Task.sleep(for: delay)
                reconnectAttempt += 1
                connect()
                if socket?.status == .connected {
                    return
                }
            }
        }
    }
}
