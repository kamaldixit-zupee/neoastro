import Foundation

@MainActor
enum FreeAskEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {

        case .freeAskSubmitted:
            if let payload = envelope.decode(FreeAskSubmittedPayload.self) {
                store.freeAskSubmissionAck = payload
                store.freeAskAnswer = nil
                AppLog.info(.chat, "FREE_ASK_SUBMITTED astrologerCount=\(payload.astrologerCount ?? 0)")
            }

        case .freeAskAnswered:
            if let payload = envelope.decode(FreeAskAnsweredPayload.self) {
                store.freeAskAnswer = payload
                AppLog.info(.chat, "FREE_ASK_ANSWERED astrologerId=\(payload.astrologerId ?? "?")")
            }

        case .astroFreeAskPriceUpdate:
            // Per-astrologer offer price update. Held in a small map so any
            // visible UI can re-render with the discounted price.
            if let payload = envelope.decode(AstroFreeAskPriceUpdatePayload.self),
               let astrologerId = payload.astrologerId,
               let price = payload.discountedPrice {
                store.freeAskOfferPrices[astrologerId] = Int(price)
            }

        case .freeChatWaitlist:
            if let payload = envelope.decode(FreeChatWaitlistPayload.self) {
                store.freeChatWaitlistText = payload.text
                AppLog.info(.chat, "FREE_CHAT_WAITLIST text=\(payload.text ?? "?")")
            }

        case .freeChatAstroId:
            if let payload = envelope.decode(FreeChatAstroIdPayload.self),
               let astroId = payload.astroId {
                store.freeChatAssignedAstroId = astroId
                AppLog.info(.chat, "FREE_CHAT_ASTRO_ID astroId=\(astroId)")
            }

        default:
            break
        }
    }
}
