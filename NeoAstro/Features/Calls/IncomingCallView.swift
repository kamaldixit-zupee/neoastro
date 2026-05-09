import SwiftUI

/// Full-screen incoming-call surface, shown via `.fullScreenCover` from
/// wherever the user happens to be when the realtime store sets
/// `incomingCall`. Audio (Agora) lands with Batch 4b — this view today
/// only handles the signaling side (accept emits, reject clears).
struct IncomingCallView: View {
    let payload: IncomingCallRequestPayload
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var ringPhase: Bool = false

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: 28) {
                Spacer()

                Text(payload.isVoiceCall == false ? "Incoming Video Call" : "Incoming Voice Call")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)

                avatar

                VStack(spacing: 6) {
                    Text(payload.userName ?? "Astrologer")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    if let astroId = payload.astroId {
                        Text("ID: \(astroId.prefix(8))…")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                actionRow

                Spacer().frame(height: 24)
            }
            .frame(maxWidth: .infinity)
        }
        .task {
            ringPhase = true
        }
    }

    private var avatar: some View {
        ZStack {
            // Pulse rings to convey "ringing" without playing audio yet.
            Circle()
                .fill(AppTheme.pinkAccent.opacity(0.18))
                .frame(width: 220, height: 220)
                .scaleEffect(ringPhase ? 1.15 : 0.85)
                .opacity(ringPhase ? 0.0 : 0.6)
                .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: ringPhase)

            Circle()
                .fill(AppTheme.pinkAccent.opacity(0.28))
                .frame(width: 170, height: 170)
                .scaleEffect(ringPhase ? 1.1 : 0.9)
                .opacity(ringPhase ? 0.0 : 0.7)
                .animation(.easeOut(duration: 1.6).delay(0.4).repeatForever(autoreverses: false), value: ringPhase)

            AvatarView(
                name: payload.userName ?? "Astrologer",
                imageURL: payload.userImage.flatMap(URL.init(string:)),
                gradient: AppTheme.primaryAvatarPalette,
                size: 132
            )
            .glassEffect(.regular, in: .circle)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 60) {
            VStack(spacing: 6) {
                Button(action: onReject) {
                    Image(systemName: "phone.down.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                }
                .buttonStyle(.glass)
                .tint(.red.opacity(0.85))
                Text("Decline")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            VStack(spacing: 6) {
                Button(action: onAccept) {
                    Image(systemName: "phone.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 68, height: 68)
                }
                .buttonStyle(.glass)
                .tint(.green.opacity(0.85))
                Text("Accept")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}
