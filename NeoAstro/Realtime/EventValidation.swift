import Foundation

/// Mirrors the EVENTS_REQUIRING_*  / EVENTS_SKIP_IF_* guards in the RN app's
/// `AppManager`. These exist to silently drop stale events that would
/// clobber current state — e.g. an `ANSWER_QUERY` for an astrologer who is
/// no longer on screen.
enum EventValidation {

    /// Drop the event if the payload's `astroId` differs from the
    /// "currently selected" astrologer (whichever one the user is browsing).
    static let requiresSelectedAstroId: Set<SocketEvent> = [
        .astroTyping,
        .astroTypingStop,
        .astroRecordingStarted,
        .astroRecordingStopped,
        .astroFreeAskPriceUpdate
    ]

    /// Drop the event if the payload's `astroId` differs from the
    /// "currently active" astrologer (the one in an open chat / call).
    static let requiresCurrentAstroId: Set<SocketEvent> = [
        .answerQuery,
        .lowBalanceNotif,
        .updatePayment,
        .inChatCallStatusUpdate
    ]

    /// Drop the event if the chat is *not* in progress.
    static let skipIfNotInProgress: Set<SocketEvent> = [
        .answerQuery,
        .astroTyping,
        .astroTypingStop,
        .astroRecordingStarted,
        .astroRecordingStopped,
        .humanAnswerSeen,
        .lowBalanceNotif,
        .updatePayment,
        .inChatCallStatusUpdate
    ]

    /// Drop the event if a chat *is* in progress (e.g. don't show "incoming
    /// chat" UI mid-session).
    static let skipIfInProgress: Set<SocketEvent> = [
        .incomingChat,
        .waitlistJoined,
        .chatStarted
    ]

    /// Pure decision logic: should this event be processed given the
    /// current session state? Caller is responsible for actually pulling
    /// the live `selectedAstroId` / `currentAstroId` / `inProgress` from
    /// the realtime store at fire time.
    static func shouldProcess(
        _ event: SocketEvent,
        payloadAstroId: String?,
        selectedAstroId: String?,
        currentAstroId: String?,
        chatInProgress: Bool
    ) -> Bool {
        if requiresSelectedAstroId.contains(event) {
            guard let payloadAstroId, payloadAstroId == selectedAstroId else { return false }
        }
        if requiresCurrentAstroId.contains(event) {
            guard let payloadAstroId, payloadAstroId == currentAstroId else { return false }
        }
        if skipIfNotInProgress.contains(event), !chatInProgress { return false }
        if skipIfInProgress.contains(event), chatInProgress { return false }
        return true
    }
}
