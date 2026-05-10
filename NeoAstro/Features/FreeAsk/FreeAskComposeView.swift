import SwiftUI
import UIKit

/// Step 2: enter the actual free-ask question.
struct FreeAskComposeView: View {
    let category: FreeAskCategory
    let onSubmitted: () -> Void

    @Environment(RealtimeStore.self) private var realtime
    @State private var question: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private let minLength = 10
    private let maxLength = 240

    private var canSubmit: Bool {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && !isSubmitting
    }

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: AppTheme.sectionSpacing) {
                categoryPill
                    .padding(.top, 12)

                Text("What would you like to ask?")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                editor

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                submitButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .navigationTitle("Compose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
                    .font(.body.weight(.semibold))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            focused = true
        }
    }

    private var categoryPill: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .foregroundStyle(AppTheme.goldGradient)
            Text(category.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }

    private var editor: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextEditor(text: $question)
                .focused($focused)
                .font(.body)
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .tint(AppTheme.pinkAccent)
                .frame(minHeight: 140, maxHeight: 220)
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
                .overlay(alignment: .topLeading) {
                    if question.isEmpty {
                        Text("e.g. When will I find a stable career path?")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: question) { _, newValue in
                    if newValue.count > maxLength {
                        question = String(newValue.prefix(maxLength))
                    }
                }

            Text("\(question.count) / \(maxLength)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.trailing, 4)
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(isSubmitting ? "Submitting…" : "Submit Question")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(AppTheme.pinkAccent)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1.0 : 0.55)
    }

    @MainActor
    private func submit() async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minLength else { return }
        focused = false
        isSubmitting = true
        errorMessage = nil

        // Stash a local snapshot so the waiting screen has something to show
        // even before the FREE_ASK_SUBMITTED ack arrives.
        realtime.freeAskLocalSubmission = FreeAskSubmission(
            category: category,
            questionText: trimmed,
            submittedAt: .now
        )

        // Try the socket first (preferred path); fall back to REST.
        await NeoAstroSocket.shared.emit(
            .freeAsk,
            payload: FreeAskSubmissionPayload(category: category.rawValue, questionText: trimmed)
        )

        do {
            try await FreeAskService.submitFreeAsk(category: category, question: trimmed)
        } catch {
            // The socket may have already accepted it. Log but don't block.
            AppLog.warn(.chat, "free ask REST fallback failed: \(error.localizedDescription)")
        }

        isSubmitting = false
        onSubmitted()
    }
}
