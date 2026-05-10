import SwiftUI
import Observation

@Observable
@MainActor
final class AstrologerProfileViewModel {

    // MARK: - State

    let astrologer: AstrologerAPI

    var profileDetail: AstrologerProfileDetail?
    var stories: [AstrologerStory] = []
    var educations: [AstrologerEducation] = []
    var reviews: [AstrologerReview] = []
    var totalReviews: Int = 0
    var averageRating: Double = 0

    var isLoadingProfile: Bool = false
    var isLoadingReviews: Bool = false

    var notifyError: String?
    var notifyState: NotifyState = .idle

    enum NotifyState: Equatable {
        case idle
        case requesting
        case subscribed
        case failed(String)
    }

    // MARK: - Init

    init(astrologer: AstrologerAPI) {
        self.astrologer = astrologer
    }

    // MARK: - Load

    /// Fire profile + reviews in parallel. Either failing leaves the other
    /// to populate; we don't show a hard failure since the list-payload
    /// already gives the screen something to render.
    func load() async {
        async let p: () = loadProfile()
        async let r: () = loadReviews()
        _ = await (p, r)
    }

    private func loadProfile() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        do {
            let detail = try await AstrologerService.getProfile(astroId: astrologer._id)
            profileDetail = detail
            stories = detail?.stories ?? []
            educations = detail?.educationAndCertifications ?? []
        } catch {
            AppLog.warn(.home, "profile load failed: \(error.localizedDescription)")
        }
    }

    private func loadReviews() async {
        isLoadingReviews = true
        defer { isLoadingReviews = false }
        do {
            let list = try await AstrologerService.reviews(astroId: astrologer._id)
            reviews = list
            totalReviews = list.count
            if !list.isEmpty {
                let sum = list.reduce(0.0) { $0 + ($1.rating ?? 0) }
                averageRating = sum / Double(list.count)
            }
        } catch {
            AppLog.warn(.home, "reviews load failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Notify me when online

    func notifyMeWhenOnline() {
        guard notifyState != .requesting, notifyState != .subscribed else { return }
        notifyState = .requesting
        Task {
            do {
                try await AstrologerService.notifyMeWhenOnline(astroId: astrologer._id)
                notifyState = .subscribed
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                AppLog.error(.home, "notifyMe failed", error: error)
                notifyState = .failed(message)
            }
        }
    }
}
