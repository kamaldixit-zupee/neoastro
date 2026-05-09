import SwiftUI
import UIKit

/// Multi-step birth-details questionnaire. Submitting calls
/// `submitAstroUserDetails` then `setOnboardingCompleted`, then asks the
/// `AuthViewModel` to advance to `.authenticated`.
struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = OnboardingViewModel()
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case name, place }

    var body: some View {
        @Bindable var vm = vm

        VStack(spacing: 0) {
            progressBar
                .padding(.top, 16)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    header

                    stepContent($vm)
                        .padding(.top, 8)

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            navigationBar
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(.body.weight(.semibold))
            }
        }
    }

    // MARK: - Progress

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<vm.totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < vm.stepNumber ? AppTheme.pinkAccent : .white.opacity(0.18))
                    .frame(height: 6)
                    .animation(.smooth, value: vm.stepNumber)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Step \(vm.stepNumber) of \(vm.totalSteps)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.pinkAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: .capsule)

            Text(vm.step.title)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(vm.step.subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Step content

    @ViewBuilder
    private func stepContent(_ vm: Bindable<OnboardingViewModel>) -> some View {
        switch self.vm.step {
        case .name:  nameStep(vm)
        case .dob:   dobStep(vm)
        case .time:  timeStep(vm)
        case .place: placeStep(vm)
        }
    }

    private func nameStep(_ vm: Bindable<OnboardingViewModel>) -> some View {
        VStack(spacing: 14) {
            TextField(
                "",
                text: vm.name,
                prompt: Text("Your name").foregroundColor(.white.opacity(0.45))
            )
            .focused($focusedField, equals: .name)
            .textContentType(.name)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .tint(AppTheme.pinkAccent)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: .capsule)

            HStack(spacing: 8) {
                ForEach(OnboardingViewModel.Gender.allCases) { g in
                    Button { self.vm.gender = g } label: {
                        HStack(spacing: 6) {
                            Image(systemName: g.icon)
                            Text(g.displayName)
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .tint(self.vm.gender == g ? AppTheme.pinkAccent : .white.opacity(0.15))
                }
            }
        }
        .onAppear { focusedField = .name }
    }

    private func dobStep(_ vm: Bindable<OnboardingViewModel>) -> some View {
        DatePicker(
            "Date of birth",
            selection: vm.dateOfBirth,
            in: ...Date(),
            displayedComponents: .date
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
        .colorScheme(.dark)   // wheel reads better on cosmic gradient
    }

    private func timeStep(_ vm: Bindable<OnboardingViewModel>) -> some View {
        VStack(spacing: 14) {
            Toggle(isOn: vm.hasTimeOfBirth) {
                Text("I know my birth time")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .tint(AppTheme.pinkAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.tightCorner))

            if self.vm.hasTimeOfBirth {
                DatePicker(
                    "Time of birth",
                    selection: vm.timeOfBirth,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
                .colorScheme(.dark)
            } else {
                Text("That's fine — astrologers will use sunrise time as a default.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }

    private func placeStep(_ vm: Bindable<OnboardingViewModel>) -> some View {
        VStack(spacing: 14) {
            TextField(
                "",
                text: vm.placeOfBirth,
                prompt: Text("City, State, Country").foregroundColor(.white.opacity(0.45))
            )
            .focused($focusedField, equals: .place)
            .textContentType(.addressCity)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .tint(AppTheme.pinkAccent)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))

            Text("Tip: include your country if you were born outside India.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .onAppear { focusedField = .place }
    }

    // MARK: - Nav

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if vm.step != .name {
                Button { vm.back() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                .tint(.white.opacity(0.18))
                .disabled(vm.isSubmitting)
            }

            Button {
                if vm.isLastStep {
                    vm.submit(auth: auth)
                } else {
                    vm.next()
                }
            } label: {
                HStack(spacing: 8) {
                    if vm.isSubmitting {
                        ProgressView().tint(.white)
                    }
                    Text(vm.isLastStep ? (vm.isSubmitting ? "Submitting…" : "Submit") : "Continue")
                        .font(.headline)
                    if !vm.isLastStep {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)
            .disabled(!vm.canAdvance || vm.isSubmitting)
            .opacity((vm.canAdvance && !vm.isSubmitting) ? 1.0 : 0.55)
        }
    }
}
