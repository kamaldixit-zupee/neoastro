import Foundation

/// String-typed event names exchanged with the backend Socket.IO layer.
///
/// Casing is **load-bearing**. The backend's validator drops events whose
/// name doesn't match exactly. Don't refactor a typo (e.g. `ANSWER_VIEWD`
/// is intentional — it ships in production with that spelling).
enum SocketEvent: String, CaseIterable, Hashable {

    // MARK: - Connection lifecycle

    case connectionAuthenticated   = "CONNECTION_AUTHENTICATED"
    case connectionManage          = "CONNECTION_MANAGE"
    case nrc                       = "NRC"
    case getUserDetails            = "GET_USER_DETAILS"

    // MARK: - Chat lifecycle

    case chatRequested             = "CHAT_REQUESTED"             // client→server
    case chatCancelled             = "CHAT_CANCELLED"             // client→server
    case chatRejected              = "CHAT_REJECTED"              // client→server
    case initiateChat              = "INITIATE_CHAT"              // client→server
    case waitlistJoined            = "WAITLIST_JOINED"
    case incomingChat              = "INCOMING_CHAT"
    case chatStarted               = "CHAT_STARTED"
    case chatInitiationFailed      = "CHAT_INITIATION_FAILED"

    // MARK: - Chat in-progress

    case raiseQuery                = "RAISE_QUERY"                // client→server
    case answerQuery               = "ANSWER_QUERY"
    case userTyping                = "USER_TYPING"                // client→server
    case astroTyping               = "ASTRO_TYPING"
    case astroTypingStop           = "ASTRO_TYPING_STOP"
    case humanAnswerSeen           = "HUMAN_ANSWER_SEEN"          // client→server
    case lowBalanceNotif           = "LOW_BALANCE_NOTIF"
    case updatePayment             = "UPDATE_PAYMENT"
    case balanceUpdated            = "BALANCE_UPDATED"

    // MARK: - Chat end

    case endChat                   = "END_CHAT"                   // client→server
    case chatEnded                 = "CHAT_ENDED"

    // MARK: - Voice call (per-minute)

    case incomingCallRequest       = "INCOMING_CALL_REQUEST"
    case callAccepted              = "CALL_ACCEPTED"
    case callRejected              = "CALL_REJECTED"
    case callCancelled             = "CALL_CANCELLED"
    case callEnded                 = "CALL_ENDED"
    case callInitiationFailed      = "CALL_INITIATION_FAILED"
    case inChatCallStatusUpdate    = "INCHAT_CALL_STATUS_UPDATE"

    // MARK: - Video / fixed-price consultation

    case videoConsultAccepted      = "VIDEO_CONSULT_ACCEPTED"
    case videoConsultRejected      = "VIDEO_CONSULT_REJECTED"
    case videoConsultTimedOut      = "VIDEO_CONSULT_TIMED_OUT"
    case videoConsultEnded         = "VIDEO_CONSULT_ENDED"
    case consultationChatStarted   = "CONSULTATION_CHAT_STARTED"
    case consultationModeSwitchAccepted  = "CONSULTATION_MODE_SWITCH_ACCEPTED"
    case consultationModeSwitchRejected  = "CONSULTATION_MODE_SWITCH_REJECTED"
    case consultationModeSwitchCancelled = "CONSULTATION_MODE_SWITCH_CANCELLED"
    case consultationReportReady   = "CONSULTATION_REPORT_READY"
    case initiateConsultFreeChat   = "INITIATE_CONSULT_FREE_CHAT"   // client→server
    case consultFreeChatStarted    = "CONSULT_FREE_CHAT_STARTED"
    case endConsultFreeChat        = "END_CONSULT_FREE_CHAT"        // client→server
    case consultFreeChatEnded      = "CONSULT_FREE_CHAT_ENDED"

    // MARK: - Free Ask

    case freeAsk                   = "FREE_ASK"                   // client→server
    case freeAskSubmitted          = "FREE_ASK_SUBMITTED"
    case freeAskAnswered           = "FREE_ASK_ANSWERED"
    case answerViewd               = "ANSWER_VIEWD"               // client→server (typo intentional)
    case freeAskSmallNudgeClicked  = "FREE_ASK_SMALL_NUDGE_CLICKED" // client→server
    case freeAskLargeNudgeClicked  = "FREE_ASK_LARGE_NUDGE_CLICKED" // client→server
    case astroFreeAskPriceUpdate   = "ASTRO_FREE_ASK_PRICE_UPDATE"

    // MARK: - Free Chat

    case initiateFreeChat          = "INITIATE_FREE_CHAT"         // client→server
    case freeChatWaitlist          = "FREE_CHAT_WAITLIST"
    case freeChatAstroId           = "FREE_CHAT_ASTRO_ID"

    // MARK: - Presence / status

    case astrologerStatusUpdate    = "ASTROLOGER_STATUS_UPDATE"
    case astrologerWaitTimeUpdate  = "ASTROLOGER_WAITTIME_UPDATE"
    case astrologerUnavailable     = "ASTROLOGER_UNAVAILABLE"
    case astrologerOnlineNotification = "ASTROLOGER_ONLINE_NOTIFICATION"
    case updateWaitTime            = "UPDATE_WAITTIME"
    case exitWaitlist              = "EXIT_WAITLIST"
    case refreshAstrologersStatus  = "REFRESH_ASTROLOGERS_STATUS"

    // MARK: - Recording

    case userRecordingStarted      = "USER_RECORDING_STARTED"     // client→server
    case userRecordingStopped      = "USER_RECORDING_STOPPED"     // client→server
    case astroRecordingStarted     = "ASTRO_RECORDING_STARTED"
    case astroRecordingStopped     = "ASTRO_RECORDING_STOPPED"

    // MARK: - Notifications / unread

    case unreadMessagesCount       = "UNREAD_MESSAGES_COUNT"
    case dynamicNudge              = "DYNAMIC_NUDGE"
    case inChatRechargeCtaClicked  = "IN_CHAT_RECHARGE_CTA_CLICKED" // client→server
}
