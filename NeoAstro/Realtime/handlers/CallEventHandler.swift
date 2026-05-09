import Foundation

/// Handles per-minute voice-call signaling. Audio media (Agora) lands with
/// Batch 4b — for now we surface enough state for `IncomingCallView` to
/// render and dismiss correctly.
@MainActor
enum CallEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {

        case .incomingCallRequest:
            if let p = envelope.decode(IncomingCallRequestPayload.self) {
                AppLog.info(.chat, "INCOMING_CALL_REQUEST callSessionId=\(p.callSessionId ?? "?") astroId=\(p.astroId ?? "?")")
                store.incomingCall = p
            }

        case .callAccepted:
            if let p = envelope.decode(CallAcceptedPayload.self) {
                AppLog.info(.chat, "CALL_ACCEPTED callSessionId=\(p.callSessionId ?? "?")")
                store.incomingCall = nil
            }

        case .callRejected, .callCancelled, .callEnded, .callInitiationFailed:
            AppLog.info(.chat, "\(event.rawValue) — clearing incoming call")
            store.incomingCall = nil

        case .inChatCallStatusUpdate:
            // Message-level call status updates land in the chat view's
            // existing message stream — defer until call messages are wired.
            AppLog.debug(.chat, "INCHAT_CALL_STATUS_UPDATE (deferred)")

        default:
            break
        }
    }
}
