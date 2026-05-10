import SwiftUI
import AVKit

enum BubbleSide { case user, astro }

struct MessageBubble: View {
    let message: ChatViewModel.ChatMessage
    var onRecharge: (() -> Void)? = nil

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
        } else if message.isVoiceCall {
            VoiceCallMessageContent(message: message, side: side)
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

    @ViewBuilder
    private var systemMessage: some View {
        if message.messageType == "SYSTEM_LOW_BALANCE" {
            lowBalanceMessage
        } else {
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

    private var lowBalanceMessage: some View {
        HStack(spacing: 10) {
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text("Low balance")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                Text(message.body)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            if let onRecharge {
                Button(action: onRecharge) {
                    Text("Recharge")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
            }
        }
        .padding(12)
        .glassEffect(.regular.tint(.orange.opacity(0.25)), in: .rect(cornerRadius: 16))
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

// MARK: - Voice-call content

private struct VoiceCallMessageContent: View {
    let message: ChatViewModel.ChatMessage
    let side: BubbleSide

    @State private var player = AudioPlayer.shared
    @State private var showVideoPlayer: Bool = false

    private var isPlayingThis: Bool {
        player.playingId == message.id && message.mediaURL != nil
    }

    private var status: VoiceCallStatus {
        VoiceCallStatus(rawValue: (message.callSessionStatus ?? "").lowercased()) ?? .unknown
    }

    private var isVideo: Bool { (message.callFormFactor ?? "").lowercased() == "video" }

    private var hasRecording: Bool {
        if let url = message.mediaURL?.absoluteString {
            return url.hasPrefix("http://") || url.hasPrefix("https://")
        }
        return false
    }

    private var icon: String {
        if isVideo { return message.isFromUser ? "video.fill" : "video" }
        return message.isFromUser ? "phone.arrow.up.right.fill" : "phone.arrow.down.left.fill"
    }

    private var titleText: String { isVideo ? "Video Call" : "Voice Call" }

    private var statusText: String {
        switch status {
        case .ringing:                return "Ringing"
        case .ongoing, .accepted:     return "Ongoing"
        case .completed, .ended:
            if let secs = message.audioDurationSeconds, secs > 0 {
                return formatDuration(secs)
            }
            return "Ended"
        case .noAnswer:               return "No answer"
        case .rejected:               return "Rejected"
        case .missed:                 return "Missed"
        case .unknown:                return "Call"
        }
    }

    private var statusColor: Color {
        switch status {
        case .ongoing, .accepted: return .green
        case .rejected, .missed:  return .orange
        default:                  return .white.opacity(0.7)
        }
    }

    var body: some View {
        Button { togglePlayback() } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.tint(AppTheme.pinkAccent.opacity(0.55)), in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(titleText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                if hasRecording {
                    Spacer(minLength: 8)
                    Image(systemName: playButtonIcon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .glassEffect(.regular, in: .circle)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(side == .user
                         ? .regular.tint(AppTheme.pinkAccent.opacity(0.45))
                         : .regular,
                         in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(!hasRecording)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoCallPlayer(url: message.mediaURL)
        }
    }

    private var playButtonIcon: String {
        if isVideo { return "play.fill" }
        return isPlayingThis ? "pause.fill" : "play.fill"
    }

    private func togglePlayback() {
        guard hasRecording, let url = message.mediaURL else { return }
        if isVideo {
            // Voice-call recordings are .mp4; AudioPlayer (AVAudioPlayer)
            // can't render the video track. Push the system video player
            // instead so both audio and video play correctly.
            showVideoPlayer = true
        } else {
            player.play(messageId: message.id, url: url)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}

private enum VoiceCallStatus: String {
    case ringing
    case ongoing
    case accepted
    case completed
    case ended
    case noAnswer = "no_answer"
    case rejected
    case missed
    case unknown
}

// MARK: - Lightbox

private struct ImageLightbox: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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

// MARK: - Video-call playback

/// Full-screen `AVPlayer` for video-call recordings. Presented from the
/// voice-call bubble when `formFactor == "video"` since `AudioPlayer`
/// (AVAudioPlayer) can't decode the video track in the .mp4 container.
private struct VideoCallPlayer: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView().tint(.white).controlSize(.large)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(16)
            }
        }
        .onAppear {
            guard let url else { return }
            let p = AVPlayer(url: url)
            player = p
            p.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
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

