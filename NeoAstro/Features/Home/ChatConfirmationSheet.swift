import SwiftUI

struct ChatConfirmationSheet: View {
    let astrologer: AstrologerAPI
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var price: Int { astrologer.displayPrice }
    private var original: Int? { astrologer.originalPrice }
    private var gradient: [String] {
        let palettes = [
            ["#7B2CBF", "#FF8FAB"],
            ["#3A86FF", "#8338EC"],
            ["#F72585", "#B5179E"],
            ["#06A77D", "#3A86FF"],
            ["#FFB703", "#FB8500"],
            ["#7209B7", "#F72585"]
        ]
        let i = abs(astrologer._id.hashValue) % palettes.count
        return palettes[i]
    }

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: 18) {
                handle

                AvatarView(
                    name: astrologer.name,
                    imageURL: astrologer.imageURL,
                    gradient: gradient,
                    size: 80
                )

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(astrologer.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        if astrologer.verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.goldGradient)
                        }
                    }
                    if let q = astrologer.qualificationText ?? astrologer.qualification {
                        Text(q)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                rateRow

                infoStrip

                Spacer(minLength: 6)

                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var handle: some View {
        Capsule()
            .fill(.white.opacity(0.3))
            .frame(width: 40, height: 4)
            .padding(.top, 8)
    }

    private var rateRow: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("₹\(price)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.goldGradient)
                Text("/min")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                if let original {
                    Text("₹\(original)")
                        .font(.footnote)
                        .strikethrough()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Text("You'll be charged per minute of consultation")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private var infoStrip: some View {
        let chips: [(icon: String, text: String)] = [
            astrologer.experience.map { ("book.fill", "\(Int($0))y") },
            astrologer.ratings.map { ("star.fill", String(format: "%.1f", $0)) },
            astrologer.chats.map { ("bubble.left.and.bubble.right.fill", "\($0)+ chats") }
        ].compactMap { $0 }

        return HStack(spacing: 10) {
            ForEach(chips, id: \.text) { chip in
                HStack(spacing: 4) {
                    Image(systemName: chip.icon)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.goldGradient)
                    Text(chip.text)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: .capsule)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onConfirm) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                    Text("Start Chat — ₹\(price)/min")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .capsule)
        }
    }
}
