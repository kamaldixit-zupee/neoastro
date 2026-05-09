import Foundation

@MainActor
enum PresenceEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {

        case .astrologerStatusUpdate:
            if let p = envelope.decode(AstrologerStatusUpdatePayload.self),
               let m = p.message,
               let astrologerId = m.astrologerId {
                store.presence[astrologerId] = AstrologerPresence(
                    chatStatus: m.chatStatus,
                    voiceStatus: m.voiceStatus,
                    consultationCurrentState: m.consultationCurrentState,
                    supportedConsultationTypes: m.supportedConsultationTypes ?? [],
                    waitTime: m.waitTime,
                    availability: m.availability,
                    lastUpdated: .now
                )
            }

        case .astrologerWaitTimeUpdate:
            // Wait-time UI is rendered per-astrologer in HomeView. Updates
            // land on the presence map's `waitTime` key.
            if let p = envelope.decode(AstrologerWaitTimeUpdatePayload.self),
               let m = p.message,
               let astroId = m.astroId {
                var existing = store.presence[astroId] ?? AstrologerPresence(
                    chatStatus: nil, voiceStatus: nil,
                    consultationCurrentState: nil,
                    supportedConsultationTypes: [],
                    waitTime: nil, availability: nil,
                    lastUpdated: .now
                )
                existing.waitTime = m.waitTimeInMins
                existing.lastUpdated = .now
                store.presence[astroId] = existing
            }

        case .astrologerUnavailable:
            if let astroId = envelope.decode(AstrologerUnavailablePayload.self)?.astrologerId {
                store.presence[astroId]?.chatStatus = "OFFLINE"
                AppLog.info(.home, "ASTROLOGER_UNAVAILABLE id=\(astroId)")
            }

        case .astrologerOnlineNotification:
            if let p = envelope.decode(AstrologerOnlineNotificationPayload.self) {
                store.astrologerOnlineBanner = p
            }

        case .refreshAstrologersStatus:
            // Bulk array update — feature views can re-fetch the list rather
            // than us merging hand-rolled deltas.
            AppLog.info(.home, "REFRESH_ASTROLOGERS_STATUS — feature views should refresh")

        default:
            break
        }
    }
}
