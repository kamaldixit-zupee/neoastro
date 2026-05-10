import SwiftUI

/// Step 3: live progress while astrologers compose answers. Driven entirely
/// by `RealtimeStore.freeAskSubmissionAck` (set on `FREE_ASK_SUBMITTED`) and
/// `freeAskAnswer` (set on `FREE_ASK_ANSWERED`). When the answer lands the
/// view auto-routes to the answer detail screen.
struct FreeAskWaitingView: View {
    let onAnswerArrived: () -> Void
    let onCancel: () -> Void

    @Environment(RealtimeStore.self) private var realtime
    @State private var progress: Double = 0
    @State private var ringPulse: Bool = false

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: AppTheme.sectionSpacing) {
                Spacer()

                pulsingHero

                Text(realtime.freeAskSubmissionAck?.text ?? "Astrologers are reading your question…")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                if let count = realtime.freeAskSubmissionAck?.astrologerCount, count > 0 {
                    Text("\(count) astrologer\(count == 1 ? "" : "s") are responding")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                progressBar
                    .padding(.top, 6)

                if let question = realtime.freeAskLocalSubmission?.questionText {
                    questionCard(question)
                }

                Spacer()

                Button(role: .destructive, action: onCancel) {
                    Text("Cancel question")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                .tint(.white.opacity(0.18))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .navigationTitle("Asking…")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { ringPulse = true }
        .task(id: realtime.freeAskAnswer) {
            // Auto-route once an answer arrives.
            if realtime.freeAskAnswer != nil {
                onAnswerArrived()
            }
        }
        .task(id: realtime.freeAskSubmissionAck?.progressBarTime) {
            // Drive the progress bar from the ack's `progressBarTime` (in
            // seconds). If unknown, default to 30 s.
            let total = TimeInterval(realtime.freeAskSubmissionAck?.progressBarTime ?? 30)
            await animateProgress(over: total)
        }
    }

    private var pulsingHero: some View {
        ZStack {
            Circle()
                .fill(AppTheme.pinkAccent.opacity(0.15))
                .frame(width: 200, height: 200)
                .scaleEffect(ringPulse ? 1.18 : 0.9)
                .opacity(ringPulse ? 0 : 0.7)
                .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: ringPulse)

            Circle()
                .fill(AppTheme.pinkAccent.opacity(0.25))
                .frame(width: 130, height: 130)
                .scaleEffect(ringPulse ? 1.08 : 0.92)
                .opacity(ringPulse ? 0.0 : 0.8)
                .animation(.easeOut(duration: 2.0).delay(0.6).repeatForever(autoreverses: false), value: ringPulse)

            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 110, height: 110)
                .glassEffect(.regular, in: .circle)
        }
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.18))
                    .frame(height: 8)
                GeometryReader { geo in
                    Capsule()
                        .fill(AppTheme.pinkAccent)
                        .frame(width: geo.size.width * progress, height: 8)
                }
                .frame(height: 8)
            }
            HStack {
                Text("Matching astrologers")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 4)
    }

    private func questionCard(_ question: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR QUESTION")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(1)
            Text(question)
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func animateProgress(over duration: TimeInterval) async {
        progress = 0
        let frames = 60
        let step: TimeInterval = duration / Double(frames)
        for i in 1...frames {
            try? await Task.sleep(for: .seconds(step))
            // Cap at 95 % so the bar leaves room for the answer arrival.
            progress = min(0.95, Double(i) / Double(frames))
            if realtime.freeAskAnswer != nil { break }
        }
    }
}
