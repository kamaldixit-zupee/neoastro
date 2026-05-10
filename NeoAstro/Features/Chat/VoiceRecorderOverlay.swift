import SwiftUI

/// Press-and-hold recording overlay that floats above the chat input bar.
/// Drives `AudioRecorder` and surfaces a live waveform-style indicator
/// + elapsed timer + slide-to-cancel affordance.
struct VoiceRecorderOverlay: View {
    @Bindable var recorder: AudioRecorder
    let dragOffset: CGFloat
    let willCancel: Bool

    var body: some View {
        HStack(spacing: 12) {
            recordingDot
            elapsed
            waveform
            Spacer()
            cancelHint
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.red.opacity(0.35)), in: .rect(cornerRadius: 22))
        .padding(.horizontal, 12)
    }

    private var recordingDot: some View {
        Circle()
            .fill(.red)
            .frame(width: 10, height: 10)
            .scaleEffect(recorder.state == .recording ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                       value: recorder.state)
    }

    private var elapsed: some View {
        let secs = Int(recorder.elapsedSeconds)
        return Text(String(format: "%d:%02d", secs / 60, secs % 60))
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
    }

    private var waveform: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<14, id: \.self) { i in
                let phase = Double(i) / 14.0
                let amplified = max(0.18, recorder.levelNormalized * (0.6 + 0.4 * sin(phase * .pi * 2)))
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: 3, height: CGFloat(amplified) * 28)
            }
        }
        .frame(height: 28)
        .animation(.smooth(duration: 0.12), value: recorder.levelNormalized)
    }

    private var cancelHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "chevron.left")
                .font(.caption.weight(.bold))
            Text(willCancel ? "Release to cancel" : "Slide to cancel")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(willCancel ? .orange : .white.opacity(0.75))
        .offset(x: max(-60, dragOffset))
        .animation(.smooth(duration: 0.15), value: willCancel)
    }
}
