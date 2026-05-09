import SwiftUI

struct MessageBubble: View {
    let message: ChatViewModel.ChatMessage

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        if message.isSystem {
            systemMessage
        } else if message.isFromUser {
            HStack {
                Spacer(minLength: 50)
                userBubble
            }
        } else {
            HStack {
                astroBubble
                Spacer(minLength: 50)
            }
        }
    }

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(message.body)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(
                    .regular.tint(AppTheme.pinkAccent.opacity(0.5)),
                    in: .rect(cornerRadius: 18)
                )
                .opacity(message.pending && !message.failed ? 0.7 : 1.0)

            HStack(spacing: 4) {
                if message.failed {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption2)
                } else if message.pending {
                    Image(systemName: "clock")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.caption2)
                } else {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white.opacity(0.55))
                        .font(.caption2.weight(.bold))
                }
                Text(Self.timeFormatter.string(from: message.sentAt))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }

    private var astroBubble: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(message.body)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))

            Text(Self.timeFormatter.string(from: message.sentAt))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
                .padding(.leading, 6)
        }
    }

    private var systemMessage: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.goldGradient)
                Text(message.body)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .capsule)
            Spacer()
        }
    }
}

struct TypingIndicator: View {
    @State private var dotPhase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(dotPhase == i ? 0.95 : 0.35))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(380))
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }
}
