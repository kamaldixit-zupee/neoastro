import Foundation
import Observation

/// Bridges socket events into observable state. Owned by `NeoAstroApp` and
/// injected into the environment so any feature view can read presence,
/// active chat, incoming call, etc., without touching the socket directly.
@Observable
@MainActor
final class RealtimeStore {

    // MARK: - Domain state

    /// True once we receive `CONNECTION_AUTHENTICATED` with no errorCode.
    var isConnected: Bool = false

    /// Total unread badge across all astrologers — driven by
    /// `UNREAD_MESSAGES_COUNT` and `NRC` events.
    var unreadCount: Int = 0

    /// Active chat session, or `nil` when no chat is in progress. Set on
    /// `CHAT_STARTED`, cleared on `CHAT_ENDED`.
    var activeChat: ActiveChat?

    /// Astrologer the user is currently *viewing* — drives validation
    /// guards for events like ASTRO_TYPING.
    var selectedAstroId: String?

    /// Astrologer in an active chat / call.
    var currentAstroId: String? { activeChat?.astroId }

    /// Realtime presence cache. Keyed by `astrologerId`.
    var presence: [String: AstrologerPresence] = [:]

    /// Latest waitlist info, if the user is queued for an astrologer.
    var waitlist: WaitlistJoinedPayload?

    /// Inbound call shown via the full-screen `IncomingCallView`.
    var incomingCall: IncomingCallRequestPayload?

    /// Latest dynamic nudges (rotated by feature screens).
    var nudges: [DynamicNudgePayload] = []

    /// Latest banner-style notification — astrologer-just-came-online.
    var astrologerOnlineBanner: AstrologerOnlineNotificationPayload?

    /// Inbound `ANSWER_QUERY` events for the open chat. Producers (the
    /// realtime handlers) append; `ChatViewModel` drains via
    /// `consumeInboundMessages()`.
    var inboundMessages: [AnswerQueryPayload] = []

    /// Last `ASTRO_TYPING` activity (used to drive a "typing…" indicator).
    var astroTypingUntil: Date?

    /// True while an `ASTRO_RECORDING_STARTED` window is open and no
    /// matching `ASTRO_RECORDING_STOPPED` has arrived. Cleared when the
    /// chat ends.
    var astrologerRecording: Bool = false

    /// Last business error from the chat-initiation pipeline.
    var lastChatInitiationError: ChatInitiationFailedPayload?

    // MARK: - Free Ask state

    /// Set on FREE_ASK_SUBMITTED — drives the waiting/progress UI.
    var freeAskSubmissionAck: FreeAskSubmittedPayload?

    /// Set on FREE_ASK_ANSWERED — clears the waiting state and surfaces the
    /// answer detail screen.
    var freeAskAnswer: FreeAskAnsweredPayload?

    /// Per-astrologer discounted price keyed by astrologer id, populated by
    /// `ASTRO_FREE_ASK_PRICE_UPDATE` events.
    var freeAskOfferPrices: [String: Int] = [:]

    /// Local snapshot of what the user just submitted, kept until either
    /// `freeAskSubmissionAck` arrives or the user cancels.
    var freeAskLocalSubmission: FreeAskSubmission?

    // MARK: - Free Chat state

    /// Display text from `FREE_CHAT_WAITLIST`.
    var freeChatWaitlistText: String?

    /// Astrologer id assigned via `FREE_CHAT_ASTRO_ID`. Once `CHAT_STARTED`
    /// fires for this astrologer, callers navigate to `ChatView`.
    var freeChatAssignedAstroId: String?

    // MARK: - Listener task

    private var listenerTask: Task<Void, Never>?

    // MARK: - Bootstrap

    /// Open the socket if we have a token and start the event-pump task.
    /// Idempotent.
    func start() async {
        guard listenerTask == nil else { return }
        await NeoAstroSocket.shared.connect()
        listenerTask = Task { [weak self] in
            for await realtime in await NeoAstroSocket.shared.events() {
                await self?.dispatch(realtime)
            }
        }
        AppLog.info(.api, "RealtimeStore started")
    }

    /// Tear down on logout.
    func stop() async {
        listenerTask?.cancel()
        listenerTask = nil
        await NeoAstroSocket.shared.disconnect()
        isConnected = false
        unreadCount = 0
        activeChat = nil
        selectedAstroId = nil
        presence.removeAll()
        waitlist = nil
        incomingCall = nil
        nudges.removeAll()
        astrologerOnlineBanner = nil
        inboundMessages.removeAll()
        astroTypingUntil = nil
        lastChatInitiationError = nil
        AppLog.info(.api, "RealtimeStore stopped")
    }

    // MARK: - Drain helpers (called by ChatViewModel)

    func consumeInboundMessages() -> [AnswerQueryPayload] {
        let drained = inboundMessages
        inboundMessages.removeAll()
        return drained
    }

    func clearActiveChat() {
        activeChat = nil
        astroTypingUntil = nil
        astrologerRecording = false
    }

    // MARK: - Dispatch

    private func dispatch(_ realtime: NeoAstroSocket.RealtimeEvent) {
        let event = realtime.event
        let envelope = realtime.envelope

        // Pull payload astroId for the validation guard before fanning into
        // a domain handler. We accept either `astroId` or `astrologerId`.
        let payloadAstroId = peekAstroId(from: envelope)
        let chatInProgress = activeChat != nil

        guard EventValidation.shouldProcess(
            event,
            payloadAstroId: payloadAstroId,
            selectedAstroId: selectedAstroId,
            currentAstroId: currentAstroId,
            chatInProgress: chatInProgress
        ) else {
            AppLog.debug(.api, "event dropped by guard event=\(event.rawValue)")
            return
        }

        switch event {
        // Connection
        case .connectionAuthenticated, .connectionManage, .nrc:
            ConnectionEventHandler.handle(event, envelope: envelope, store: self)
        // Chat
        case .chatStarted, .chatEnded, .chatInitiationFailed,
             .answerQuery, .astroTyping, .astroTypingStop,
             .astroRecordingStarted, .astroRecordingStopped,
             .lowBalanceNotif, .updatePayment, .balanceUpdated,
             .waitlistJoined, .incomingChat, .exitWaitlist, .updateWaitTime:
            ChatEventHandler.handle(event, envelope: envelope, store: self)
        // Voice call
        case .incomingCallRequest, .callAccepted, .callRejected,
             .callCancelled, .callEnded, .callInitiationFailed,
             .inChatCallStatusUpdate:
            CallEventHandler.handle(event, envelope: envelope, store: self)
        // Presence
        case .astrologerStatusUpdate, .astrologerWaitTimeUpdate,
             .astrologerUnavailable, .astrologerOnlineNotification,
             .refreshAstrologersStatus:
            PresenceEventHandler.handle(event, envelope: envelope, store: self)
        // Notifications / unread / nudges
        case .unreadMessagesCount, .dynamicNudge:
            NotificationEventHandler.handle(event, envelope: envelope, store: self)
        // Free Ask + Free Chat
        case .freeAskSubmitted, .freeAskAnswered, .astroFreeAskPriceUpdate,
             .freeChatWaitlist, .freeChatAstroId:
            FreeAskEventHandler.handle(event, envelope: envelope, store: self)
        default:
            AppLog.debug(.api, "event handled=false event=\(event.rawValue)")
        }
    }

    // MARK: - Free Ask helpers

    func resetFreeAsk() {
        freeAskSubmissionAck = nil
        freeAskAnswer = nil
        freeAskLocalSubmission = nil
    }

    func resetFreeChat() {
        freeChatWaitlistText = nil
        freeChatAssignedAstroId = nil
    }

    private func peekAstroId(from envelope: SocketEnvelopeIn) -> String? {
        struct Peek: Decodable {
            let astroId: String?
            let astrologerId: String?
        }
        if let peek = envelope.decode(Peek.self) {
            return peek.astroId ?? peek.astrologerId
        }
        return nil
    }
}

// MARK: - Lightweight value types

struct ActiveChat: Equatable {
    let chatId: String
    let astroId: String
    let isFixedPriceConsultation: Bool
    let consultationType: String?
    let startedAt: Date
    var sequenceCounter: Int
}

struct AstrologerPresence: Hashable {
    var chatStatus: String?
    var voiceStatus: String?
    var consultationCurrentState: String?
    var supportedConsultationTypes: [String]
    var waitTime: Int?
    var availability: Bool?
    var lastUpdated: Date
}
