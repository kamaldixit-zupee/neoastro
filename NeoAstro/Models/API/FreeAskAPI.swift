import Foundation

/// Hardcoded fallback categories for `SelectFreeQuestionView`. The RN app
/// fetches these from a config endpoint; for MVP we ship a sensible static
/// set so the screen renders even on the first cold launch.
enum FreeAskCategory: String, CaseIterable, Identifiable, Hashable {
    case love       = "LOVE"
    case marriage   = "MARRIAGE"
    case career     = "CAREER"
    case education  = "EDUCATION"
    case health     = "HEALTH"
    case finance    = "FINANCE"
    case family     = "FAMILY"
    case business   = "BUSINESS"
    case children   = "CHILDREN"
    case general    = "GENERAL"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .love:      "Love & Relationships"
        case .marriage:  "Marriage"
        case .career:    "Career & Job"
        case .education: "Education"
        case .health:    "Health"
        case .finance:   "Finance"
        case .family:    "Family"
        case .business:  "Business"
        case .children:  "Children"
        case .general:   "Anything else"
        }
    }
    var icon: String {
        switch self {
        case .love:      "heart.fill"
        case .marriage:  "ring.circle.fill"
        case .career:    "briefcase.fill"
        case .education: "book.fill"
        case .health:    "cross.case.fill"
        case .finance:   "indianrupeesign.circle.fill"
        case .family:    "house.fill"
        case .business:  "chart.line.uptrend.xyaxis"
        case .children:  "figure.and.child.holdinghands"
        case .general:   "sparkles"
        }
    }
}

// REST submission body used as a fallback if the socket is down.
struct FreeAskRestBody: Encodable {
    let category: String
    let questionText: String
    var birthDateTime: String? = nil
    var birthLocation: String? = nil
}

struct FreeAskRestResponse: Decodable {
    let success: Bool?
    let acceptedText: String?
}

/// Tracks what the user just submitted so we can render the live waiting UI
/// even after the FREE_ASK_SUBMITTED ack hasn't arrived yet.
struct FreeAskSubmission: Hashable {
    let category: FreeAskCategory
    let questionText: String
    let submittedAt: Date
}
