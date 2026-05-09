import Foundation

@MainActor
enum ChatEventHandler {

    static func handle(_ event: SocketEvent, envelope: SocketEnvelopeIn, store: RealtimeStore) {
        switch event {

        case .chatStarted:
            guard let p = envelope.decode(ChatStartedPayload.self),
                  let chatId = p.chatId,
                  let astroId = p.astroId else { return }
            AppLog.info(.chat, "CHAT_STARTED chatId=\(chatId) astroId=\(astroId) fp=\(p.isFixedPriceConsultation == true)")
            store.activeChat = ActiveChat(
                chatId: chatId,
                astroId: astroId,
                isFixedPriceConsultation: p.isFixedPriceConsultation == true,
                consultationType: p.consultationType,
                startedAt: .now,
                sequenceCounter: 0
            )
            store.waitlist = nil
            store.lastChatInitiationError = nil

        case .chatInitiationFailed:
            if let p = envelope.decode(ChatInitiationFailedPayload.self) {
                store.lastChatInitiationError = p
                store.waitlist = nil
                AppLog.warn(.chat, "CHAT_INITIATION_FAILED astroId=\(p.astroId ?? "?") balance=\(p.balanceInsufficient == true)")
            }

        case .chatEnded:
            if let p = envelope.decode(ChatEndedPayload.self) {
                AppLog.info(.chat, "CHAT_ENDED chatId=\(p.chatId ?? "?")")
            }
            store.clearActiveChat()

        case .answerQuery:
            if let p = envelope.decode(AnswerQueryPayload.self) {
                AppLog.info(.chat, "ANSWER_QUERY id=\(p._id ?? "?") seq=\(p.sequenceId.map(String.init) ?? "?")")
                store.inboundMessages.append(p)
            }

        case .astroTyping:
            if let p = envelope.decode(AstroTypingPayload.self) {
                let timeout = TimeInterval(p.typingTimeout ?? 120)
                store.astroTypingUntil = .now.addingTimeInterval(timeout)
            }

        case .astroTypingStop:
            store.astroTypingUntil = nil

        case .waitlistJoined:
            if let p = envelope.decode(WaitlistJoinedPayload.self) {
                store.waitlist = p
                AppLog.info(.chat, "WAITLIST_JOINED astrologerId=\(p.astrologerId ?? "?")")
            }

        case .incomingChat:
            // Surface for an "incoming chat" UI. State held by feature views.
            AppLog.info(.chat, "INCOMING_CHAT received")

        case .lowBalanceNotif:
            // Synthesise a system message into the active chat. The chat view
            // model picks it up via the next inboundMessages drain.
            if let p = envelope.decode(LowBalancePayload.self) {
                let synthetic = AnswerQueryPayload(
                    _id: "sys_\(UUID().uuidString)",
                    message: p.message ?? "Your balance is low. Add funds to continue.",
                    messageType: "SYSTEM_LOW_BALANCE",
                    createdAt: Date().timeIntervalSince1970,
                    sequenceId: nil,
                    seen: nil,
                    astroId: p.astroId,
                    audioUrl: nil,
                    audioDuration: nil,
                    mediaUrls: nil,
                    repliedAgainst: nil
                )
                store.inboundMessages.append(synthetic)
            }

        case .balanceUpdated, .updatePayment, .updateWaitTime, .exitWaitlist:
            // No domain state in the store yet; feature ViewModels listen
            // directly via their own subscriptions.
            break

        default:
            break
        }
    }
}
