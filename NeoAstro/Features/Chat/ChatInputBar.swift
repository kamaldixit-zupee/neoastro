import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var focused: Bool
    let onSend: () -> Void
    let onTypingTouch: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "",
                text: $text,
                prompt: Text("Type a message…").foregroundColor(.white.opacity(0.45)),
                axis: .vertical
            )
            .focused($focused)
            .lineLimit(1...4)
            .font(.subheadline)
            .foregroundStyle(.white)
            .tint(AppTheme.pinkAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .capsule)
            .onChange(of: text) { _, _ in
                onTypingTouch()
            }

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)
            .disabled(!canSend)
            .opacity(canSend ? 1.0 : 0.55)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
