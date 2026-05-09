import SwiftUI
import Observation

@Observable
@MainActor
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case name, dob, time, place

        var title: String {
            switch self {
            case .name:  "What's your name?"
            case .dob:   "When were you born?"
            case .time:  "What time were you born?"
            case .place: "Where were you born?"
            }
        }

        var subtitle: String {
            switch self {
            case .name:  "Astrologers use this to personalise your reading."
            case .dob:   "Your date of birth determines your zodiac sign."
            case .time:  "Birth time gives a more accurate Kundli. Skip if unknown."
            case .place: "We use this to compute the exact celestial chart."
            }
        }
    }

    enum Gender: String, CaseIterable, Identifiable {
        case male = "MALE", female = "FEMALE", other = "OTHER"
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .male:   "Male"
            case .female: "Female"
            case .other:  "Other"
            }
        }
        var icon: String {
            switch self {
            case .male:   "person.fill"
            case .female: "person.fill"
            case .other:  "person.crop.circle.fill"
            }
        }
    }

    // MARK: - State

    var step: Step = .name

    var name: String = ""
    var gender: Gender = .female

    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    var hasTimeOfBirth: Bool = true
    var timeOfBirth: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    var placeOfBirth: String = ""

    var isSubmitting: Bool = false
    var errorMessage: String?

    // MARK: - Validation

    var canAdvance: Bool {
        switch step {
        case .name:  return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .dob:   return true
        case .time:  return true   // optional — "skip" toggle allowed
        case .place: return !placeOfBirth.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var progressFraction: Double {
        let total = Double(Step.allCases.count)
        let current = Double(step.rawValue + 1)
        return current / total
    }

    var stepNumber: Int { step.rawValue + 1 }
    var totalSteps: Int { Step.allCases.count }
    var isLastStep: Bool { step == .place }

    // MARK: - Navigation

    func next() {
        guard canAdvance else { return }
        if let nextStep = Step(rawValue: step.rawValue + 1) {
            step = nextStep
        }
    }

    func back() {
        if let prevStep = Step(rawValue: step.rawValue - 1) {
            step = prevStep
        }
    }

    // MARK: - Submission

    func submit(auth: AuthViewModel) {
        guard !isSubmitting else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPlace = placeOfBirth.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedPlace.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil
        AppLog.info(.onboarding, "VM · submit start")

        Task {
            do {
                let body = AstroUserDetailsBody(
                    name: trimmedName,
                    dateOfBirth: Self.dobFormatter.string(from: dateOfBirth),
                    timeOfBirth: hasTimeOfBirth ? Self.timeFormatter.string(from: timeOfBirth) : nil,
                    placeOfBirth: trimmedPlace,
                    gender: gender.rawValue,
                    zupeeUserId: TokenStore.shared.zupeeUserId
                )
                try await OnboardingService.submitAstroUserDetails(body)
                try await OnboardingService.setOnboardingCompleted()
                AppLog.info(.onboarding, "VM · submit success → authenticated")
                auth.onboardingCompleted()
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                AppLog.error(.onboarding, "VM · submit failed", error: error)
            }
            isSubmitting = false
        }
    }

    // MARK: - Formatters

    private static let dobFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}
