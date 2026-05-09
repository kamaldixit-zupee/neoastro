import SwiftUI

struct ChatConfirmationSheet: View {
    let astrologer: AstrologerAPI
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var price: Int { astrologer.displayPrice }
    private var original: Int? { astrologer.originalPrice }
    private var palette: [String] { AppTheme.avatarPalette(for: astrologer._id) }

    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            AvatarView(
                name: astrologer.name,
                imageURL: astrologer.imageURL,
                gradient: palette,
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
        .padding(.top, 12)
        .padding(.bottom, 24)
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
        .padding(AppTheme.cardPadding)
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
            .buttonStyle(.glass)
            .tint(.white.opacity(0.2))
        }
    }
}
