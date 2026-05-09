import SwiftUI

struct AstrologerCard: View {
    let astrologer: AstrologerAPI
    let height: CGFloat
    let onTap: () -> Void
    let onChat: () -> Void

    private var displayName: String { astrologer.name }
    private var qualification: String {
        astrologer.qualificationText
            ?? astrologer.qualification
            ?? astrologer.heading
            ?? "Astrologer"
    }
    private var experienceText: String {
        astrologer.experienceText
            ?? (astrologer.experience.map { "\(Int($0))y" } ?? "")
    }
    private var rating: Double { astrologer.ratings ?? 0 }
    private var price: Int { astrologer.displayPrice }
    private var originalPrice: Int? { astrologer.originalPrice }
    private var isOnline: Bool {
        if let state = astrologer.status?.state { return state == "ONLINE" }
        return astrologer.isActive ?? false
    }
    private var gradient: [String] { AppTheme.avatarPalette(for: astrologer._id) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                avatar
                details
                Spacer(minLength: 8)
                chatColumn
            }
            .padding(14)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: AppTheme.cardCorner))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCorner)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            AvatarView(
                name: displayName,
                imageURL: astrologer.imageURL,
                gradient: gradient,
                size: 76
            )

            if isOnline {
                Circle()
                    .fill(.green)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if astrologer.verified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.goldGradient)
                }
            }

            Text(qualification)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)

            HStack(spacing: 8) {
                if !experienceText.isEmpty {
                    Label(experienceText, systemImage: "book.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }

                if rating > 0 {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.yellow)
                }
            }

            if price > 0 {
                HStack(spacing: 4) {
                    Text("₹\(price)/min")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(AppTheme.goldGradient)
                    if let originalPrice {
                        Text("₹\(originalPrice)")
                            .font(.caption2)
                            .strikethrough()
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private var chatColumn: some View {
        VStack(spacing: 8) {
            Button(action: onChat) {
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                        .font(.footnote)
                    Text("Chat")
                        .font(.footnote.weight(.semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.glass)
            .tint(AppTheme.pinkAccent)
        }
    }
}
