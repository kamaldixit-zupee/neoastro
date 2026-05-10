import Foundation

@MainActor
enum ConnectionEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {
        case .connectionAuthenticated:
            let payload = envelope.decode(ConnectionAuthenticatedPayload.self)
            if let code = payload?.errorCode {
                AppLog.warn(.socketIO, "connection authenticated errorCode=\(code) — forcing logout")
                Task { await store.stop() }
                AuthService.logout()
                return
            }
            store.isConnected = true
            AppLog.info(.socketIO, "authenticated — isConnected=true")
        case .connectionManage:
            AppLog.warn(.socketIO, "CONNECTION_MANAGE — server-forced logout")
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
