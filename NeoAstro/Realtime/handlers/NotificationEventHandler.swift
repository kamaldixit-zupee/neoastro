import Foundation

@MainActor
enum NotificationEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {

        case .unreadMessagesCount:
            if let count = envelope.decode(UnreadMessagesPayload.self)?.unreadMessages {
                store.unreadCount = count
                AppLog.info(.api, "UNREAD_MESSAGES_COUNT=\(count)")
            }

        case .dynamicNudge:
            if let p = envelope.decode(DynamicNudgePayload.self) {
                store.nudges.append(p)
                // Keep the buffer tight — only the 5 most recent.
                if store.nudges.count > 5 {
                    store.nudges.removeFirst(store.nudges.count - 5)
                }
            }

        default:
            break
        }
    }
}
