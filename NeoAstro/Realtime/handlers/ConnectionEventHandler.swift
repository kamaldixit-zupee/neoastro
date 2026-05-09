import Foundation

@MainActor
enum ConnectionEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {
        case .connectionAuthenticated:
            let payload = envelope.decode(ConnectionAuthenticatedPayload.self)
            if let code = payload?.errorCode {
                AppLog.warn(.api, "connection authenticated errorCode=\(code) — forcing logout")
                Task { await store.stop() }
                AuthService.logout()
                return
            }
            store.isConnected = true
            AppLog.info(.api, "socket authenticated")
        case .connectionManage:
            AppLog.warn(.api, "CONNECTION_MANAGE — server-forced logout")
            Task { await store.stop() }
            AuthService.logout()
        case .nrc:
            if let count = envelope.decode(NotificationCountPayload.self)?.ct {
                store.unreadCount = count
            }
        default:
            break
        }
    }
}
