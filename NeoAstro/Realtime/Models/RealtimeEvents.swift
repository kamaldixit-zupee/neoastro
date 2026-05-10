import Foundation

// MARK: - Connection

struct ConnectionAuthenticatedPayload: Decodable {
    let errorCode: Int?
}

struct NotificationCountPayload: Decodable {
    let ct: Int?
}

// MARK: - Chat lifecycle

struct ChatRequestedPayload: Encodable {
    let astroId: String
    var isClickedFromFreeAsk: Bool = false
    var isOffline: Bool = false
}

struct InitiateChatPayload: Encodable {
    let astroId: String
    var continueSession: Bool = false
}

struct WaitlistJoinedPayload: Decodable, Hashable {
    let astrologerId: String?
    let isNotificationSubscribed: Bool?
    let waitlistHeading: String?
    let displayText: String?
    let timeOut: Int?
}

struct IncomingChatPayload: Decodable, Hashable {
    let astrologerId: String?
    let astrologerName: String?
    let astrologerImage: String?
    let title: String?
    let timeOut: Int?
    let expiryTime: Double?
}

struct ChatStartedPayload: Decodable, Hashable {
    let chatId: String?
    let astroId: String?
    let userId: String?
    let callSessionId: String?
    let isFixedPriceConsultation: Bool?
    let consultationType: String?
    let ts: Double?
    let timeLeft: Double?
    let suggestedQuestions: [String]?
}

struct ChatInitiationFailedPayload: Decodable, Hashable {
    let astroId: String?
    let balanceInsufficient: Bool?
    let heading: String?
    let subHeading: String?
    let buttonText: String?
    let isFixedPriceConsultation: Bool?
    let NAVIGATE_TO_SCREEN: String?
}

struct ChatEndedPayload: Decodable, Hashable {
    let callSessionId: String?
    let astroId: String?
    let chatId: String?
}

// MARK: - Chat in-progress

struct RaiseQueryPayload: Encodable {
    let chatId: String
    let astroId: String
    let message: String
    let messageType: String           // "TEXT" | "AUDIO" | "IMAGE"
    let sequenceId: Int
    var mediaUrls: [String]? = nil
    var audioDuration: Int? = nil
    var replyTo: String? = nil
    var originalMessage: String? = nil
}

struct AnswerQueryPayload: Decodable, Hashable {
    let _id: String?
    let message: String?
    let messageType: String?
    let createdAt: Double?
    let sequenceId: Int?
    let seen: Bool?
    let astroId: String?
    let audioUrl: String?
    let audioDuration: Int?
    let mediaUrls: [String]?
    let repliedAgainst: String?
}

struct UserTypingPayload: Encodable {
    let astroId: String
    let chatId: String
    var typingTimeout: Int? = nil
}

struct AstroTypingPayload: Decodable, Hashable {
    let astrologerId: String?
    let typingTimeout: Int?
}

struct AstroTypingStopPayload: Decodable, Hashable {
    let astrologerId: String?
}

struct LowBalancePayload: Decodable, Hashable {
    let astroId: String?
    let messageType: String?
    let message: String?
}

struct UpdatePaymentPayload: Decodable, Hashable {
    let chatEndTime: Double?
}

struct EndChatPayload: Encodable {
    let chatId: String
    var endedBy: String = "USER"
}

struct HumanAnswerSeenPayload: Encodable {
    let chatId: String
    let sequenceId: Int
}

// MARK: - Voice call

struct IncomingCallRequestPayload: Decodable, Hashable {
    let astroId: String?
    let userName: String?
    let userImage: String?
    let token: String?
    let channelName: String?
    let callSessionId: String?
    let expiryTime: Double?
    let timeOut: Int?
    let isVoiceCall: Bool?
}

struct CallAcceptedPayload: Decodable, Hashable {
    let callSessionId: String?
    let astroId: String?
    let timeLeftToChat: Double?
}

struct CallEndedPayload: Decodable, Hashable {
    let callSessionId: String?
    let astroId: String?
}

struct CallRejectedPayload: Decodable, Hashable {
    let astroId: String?
    let callSessionId: String?
    let currentCallStatus: String?
    let message: String?
}

struct CallCancelledPayload: Decodable, Hashable {
    let astroId: String?
    let callSessionId: String?
    let zupeeUserId: Int?
}

struct CallInitiationFailedPayload: Decodable, Hashable {
    let astroId: String?
    let callSessionId: String?
    let heading: String?
    let subHeading: String?
    let buttonText: String?
}

// MARK: - Presence

struct AstrologerStatusUpdatePayload: Decodable, Hashable {
    let message: AstrologerStatusMessage?

    struct AstrologerStatusMessage: Decodable, Hashable {
        let astrologerId: String?
        let chatStatus: String?
        let voiceStatus: String?
        let consultationCurrentState: String?
        let supportedConsultationTypes: [String]?
        let waitTime: Int?
        let availability: Bool?
    }
}

struct AstrologerWaitTimeUpdatePayload: Decodable, Hashable {
    let message: AstrologerWaitTimeMessage?

    struct AstrologerWaitTimeMessage: Decodable, Hashable {
        let astroId: String?
        let displayText: String?
        let extimatedTimestamp: Double?
        let backgroundColor: String?
        let waitTimeInMins: Int?
        let status: String?
    }
}

struct AstrologerUnavailablePayload: Decodable, Hashable {
    let astrologerId: String?
}

struct AstrologerOnlineNotificationPayload: Decodable, Hashable {
    let astrologerId: String?
    let name: String?
    let image: String?
    let subtext: String?
    let price: String?
    let timestamp: Double?
}

// MARK: - Free Ask

struct FreeAskSubmittedPayload: Decodable, Hashable {
    let astrologers: [FreeAskAstrologerLite]?
    let astrologerCount: Int?
    let progressBarCount: Int?
    let progressBarTime: Int?      // seconds
    let text: String?
    let acceptedText: String?
}

struct FreeAskAnsweredPayload: Decodable, Hashable {
    let qaAskedExpiryTime: Double?
    let questionText: String?
    let recommendedAstrologers: [FreeAskAstrologerLite]?
    let astrologers: [FreeAskAstrologerLite]?
    let viewAllText: String?
    let askNextOneInText: String?
    let offerValidText: String?
    let answer: String?
    let astrologerName: String?
    let astrologerImage: String?
    let astrologerId: String?
}

struct FreeAskAstrologerLite: Decodable, Hashable, Identifiable {
    let _id: String?
    let name: String?
    let image: String?
    let price: Double?
    let discountedPrice: Double?
    let rating: Double?

    var id: String { _id ?? UUID().uuidString }

    var displayName: String { name ?? "Astrologer" }
    var displayPrice: Int { Int(discountedPrice ?? price ?? 0) }
    var imageURL: URL? { image.flatMap(URL.init(string:)) }
}

struct AstroFreeAskPriceUpdatePayload: Decodable, Hashable {
    let astrologerId: String?
    let discountedPrice: Double?
    let timestamp: Double?
}

// Outbound

struct FreeAskSubmissionPayload: Encodable {
    let category: String
    let questionText: String
    var birthDateTime: String? = nil
    var birthLocation: String? = nil
}

struct AnswerViewedPayload: Encodable {
    let astroId: String
}

// MARK: - Free Chat

struct InitiateFreeChatPayload: Encodable {
    let zupeeUserId: Int
}

struct FreeChatWaitlistPayload: Decodable, Hashable {
    let text: String?
}

struct FreeChatAstroIdPayload: Decodable, Hashable {
    let astroId: String?
}

// MARK: - Notifications

struct DynamicNudgePayload: Decodable, Hashable {
    let astroId: String?
    let userZuid: Int?
    let nudgeType: String?
    let data: NudgeData?

    struct NudgeData: Decodable, Hashable {
        let text: String?
    }
}

struct UnreadMessagesPayload: Decodable, Hashable {
    let unreadMessages: Int?
}
