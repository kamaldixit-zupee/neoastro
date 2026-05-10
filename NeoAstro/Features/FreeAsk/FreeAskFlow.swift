import SwiftUI

/// Sheet wrapper that owns the Free Ask 4-step navigation:
/// `select → compose → waiting → answers`.
/// The current step lives in this view's `path` so closing the sheet drops
/// the local navigation, but the *waiting* / *answer* state lives on
/// `RealtimeStore` so it survives close+reopen.
struct FreeAskFlow: View {
    let onClose: () -> Void
    let onPickAstrologer: (String) -> Void  // astroId

    @Environment(RealtimeStore.self) private var realtime
    @State private var path: [FreeAskStep] = []

    enum FreeAskStep: Hashable {
        case compose(FreeAskCategory)
        case waiting
        case answers
    }

    var body: some View {
        NavigationStack(path: $path) {
            // Step 1 always shows when sheet first appears, except when we
            // already have a live submission — in which case skip straight
            // to waiting (or answers if the answer arrived while the sheet
            // was closed).
            initialView
                .navigationDestination(for: FreeAskStep.self) { step in
                    switch step {
                    case .compose(let category):
                        FreeAskComposeView(
                            category: category,
                            onSubmitted: {
                                path = [.waiting]
                            }
                        )
                    case .waiting:
                        FreeAskWaitingView(
                            onAnswerArrived: {
                                path = [.answers]
                            },
                            onCancel: {
                                realtime.resetFreeAsk()
                                onClose()
                            }
                        )
                    case .answers:
                        FreeAskAnswersView(
                            onClose: {
                                realtime.resetFreeAsk()
                                onClose()
                            },
                            onPickAstrologer: { astroId in
                                realtime.resetFreeAsk()
                                onPickAstrologer(astroId)
                            }
                        )
                    }
                }
        }
        .interactiveDismissDisabled(realtime.freeAskLocalSubmission != nil)
        .onAppear {
            // If the user closed the sheet while an ask was in flight,
            // reopening resumes at the right step.
            if realtime.freeAskAnswer != nil {
                path = [.answers]
            } else if realtime.freeAskLocalSubmission != nil {
                path = [.waiting]
            }
        }
    }

    @ViewBuilder
    private var initialView: some View {
        SelectFreeQuestionView { category in
            path = [.compose(category)]
        }
    }
}
