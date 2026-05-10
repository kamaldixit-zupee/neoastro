import SwiftUI

enum BubbleSide { case user, astro }

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
                bubble(for: message, side: .user)
            }
        } else {
            HStack {
                bubble(for: message, side: .astro)
                Spacer(minLength: 50)
            }
        }
    }

    @ViewBuilder
    private func bubble(for message: ChatViewModel.ChatMessage, side: BubbleSide) -> some View {
        VStack(alignment: side == .user ? .trailing : .leading, spacing: 3) {
            content(for: message, side: side)
            statusLine(for: message, side: side)
        }
    }

    @ViewBuilder
    private func content(for message: ChatViewModel.ChatMessage, side: BubbleSide) -> some View {
        if message.isAudio {
            AudioMessageContent(message: message, side: side)
        } else if message.isImage {
            ImageMessageContent(message: message, side: side)
        } else {
            TextMessageContent(message: message, side: side)
        }
    }

    private func statusLine(for message: ChatViewModel.ChatMessage, side: BubbleSide) -> some View {
        HStack(spacing: 4) {
            if side == .user {
                if message.failed {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange).font(.caption2)
                } else if message.pending {
                    Image(systemName: "clock")
                        .foregroundStyle(.white.opacity(0.5)).font(.caption2)
                } else {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white.opacity(0.55)).font(.caption2.weight(.bold))
                }
            }
            Text(Self.timeFormatter.string(from: message.sentAt))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(side == .user ? .trailing : .leading, 6)
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

// MARK: - Text content

private struct TextMessageContent: View {
    let message: ChatViewModel.ChatMessage
    let side: BubbleSide

    var body: some View {
        Text(message.body)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(side == .user
                         ? .regular.tint(AppTheme.pinkAccent.opacity(0.5))
                         : .regular,
                         in: .rect(cornerRadius: 18))
            .opacity(message.pending && !message.failed ? 0.7 : 1.0)
    }
}

// MARK: - Audio content

private struct AudioMessageContent: View {
    let message: ChatViewModel.ChatMessage
    let side: BubbleSide

    @State private var player = AudioPlayer.shared

    private var isPlayingThis: Bool { player.playingId == message.id }
    private var durationLabel: String {
        let secs = message.audioDurationSeconds ?? 0
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    var body: some View {
        Button { toggle() } label: {
            HStack(spacing: 10) {
                Image(systemName: isPlayingThis ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .glassEffect(.regular.tint(AppTheme.pinkAccent.opacity(0.55)), in: .circle)

                ZStack(alignment: .leading) {
                    // Waveform track (static; the bar fills from left as
                    // playback advances).
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .frame(height: 4)
                    GeometryReader { geo in
                        Capsule()
                            .fill(AppTheme.pinkAccent)
                            .frame(width: geo.size.width * (isPlayingThis ? player.progress : 0), height: 4)
                            .animation(.linear(duration: 0.1), value: player.progress)
                    }
                    .frame(height: 4)
                }
                .frame(width: 110)

                Text(durationLabel)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(side == .user
                         ? .regular.tint(AppTheme.pinkAccent.opacity(0.45))
                         : .regular,
                         in: .rect(cornerRadius: 18))
            .opacity(message.pending && !message.failed ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        guard let url = message.mediaURL else { return }
        player.play(messageId: message.id, url: url)
    }
}

// MARK: - Image content

private struct ImageMessageContent: View {
    let message: ChatViewModel.ChatMessage
    let side: BubbleSide

    @State private var showLightbox: Bool = false

    var body: some View {
        Button { showLightbox = true } label: {
            ZStack {
                if let url = message.mediaURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .failure:
                            failurePlaceholder
                        case .empty:
                            ProgressView().tint(.white)
                        @unknown default:
                            failurePlaceholder
                        }
                    }
                } else {
                    ProgressView().tint(.white)
                }
            }
            .frame(width: 220, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
            .opacity(message.pending && !message.failed ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(message.mediaURL == nil)
        .sheet(isPresented: $showLightbox) {
            ImageLightbox(url: message.mediaURL)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var failurePlaceholder: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.55))
            Text("Image unavailable")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

// MARK: - Lightbox

private struct ImageLightbox: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CosmicBackground()

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit().padding(20)
                    case .failure:
                        Text("Couldn't load image")
                            .foregroundStyle(.white)
                    default:
                        ProgressView().tint(.white).controlSize(.large)
                    }
                }
            } else {
                Text("No image")
                    .foregroundStyle(.white)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title2)
                }
            }
        }
    }
}

// MARK: - Typing indicator (unchanged from Batch 4)

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

