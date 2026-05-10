import SwiftUI

/// Sheet wrapper for Free Chat. Single screen today (the waiting view) —
/// once `FREE_CHAT_ASTRO_ID` arrives the caller dismisses the sheet and
/// pushes `ChatView` from `HomeView`'s navigation stack.
struct FreeChatFlow: View {
    let onClose: () -> Void
    let onAssigned: (String) -> Void  // astroId

    @Environment(RealtimeStore.self) private var realtime

    var body: some View {
        NavigationStack {
            FreeChatWaitingView(
                onAssigned: onAssigned,
                onCancel: onClose
            )
        }
        .interactiveDismissDisabled(realtime.freeChatAssignedAstroId == nil)
    }
}
