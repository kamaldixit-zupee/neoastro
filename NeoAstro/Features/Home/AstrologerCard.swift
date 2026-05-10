import SwiftUI

/// Home / Search astrologer card. Layout mirrors the RN reference at
/// `zupee-rn-astro/src/screens/home/card/Card.tsx`:
///
/// ```
/// ┌────────────────────────────────────┐
/// │  ┌───────────┐   Available now     │
/// │  │           │   ₹15/min           │
/// │  │   Image   │   ┌───────┐ ┌───┐   │
/// │  │           │   │Connect│ │ 🔔 │   │  ← bell only when offline
/// │  └───────────┘   └───────┘ └───┘   │
/// │  Name ✓ │ 5 Yrs · 4.7 · 12k        │
/// │  Vedic • Tarot • Vastu │ Hindi • English│
/// └────────────────────────────────────┘
/// ```
struct AstrologerCard: View {
    let astrologer: AstrologerAPI
    let onTap: () -> Void
    let onChat: () -> Void
    var onNotify: (() -> Void)? = nil
    var notified: Bool = false

    // MARK: - Derived state

    private var isOnline: Bool {
        if let state = astrologer.status?.state?.uppercased() { return state == "ONLINE" }
        return astrologer.isActive ?? false
    }
    private var isBusy: Bool {
        (astrologer.status?.state?.uppercased() == "BUSY")
    }
    private var isOffline: Bool { !isOnline && !isBusy }

    private var displayPrice: Int { astrologer.displayPrice }
    private var hasDiscount: Bool { astrologer.originalPrice != nil }
    private var rating: Double { astrologer.ratings ?? 0 }

    private var studies: [String]   { Array((astrologer.studies ?? []).prefix(3)) }
    private var languages: [String] { Array((astrologer.languages ?? []).prefix(2)) }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                topRow
                bottomRow
            }
            .padding(12)
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

    // MARK: - Top half

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            astroImage

            VStack(spacing: 6) {
                statusBadge
                priceView
                Spacer(minLength: 4)
                actionButtons
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var astroImage: some View {
        AsyncImage(url: astrologer.imageURL) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure, .empty:
                ZStack {
                    LinearGradient(
                        colors: AppTheme.avatarPalette(for: astrologer._id).map { Color(hex: $0) },
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(.white.opacity(0.6))
                }
            @unknown default:
                Color.gray.opacity(0.4)
            }
        }
        .frame(width: 140, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .saturation(isOffline ? 0 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isOnline {
            badgePill(text: "Available now", textColor: Color(red: 0.04, green: 0.53, blue: 0.12), bg: Color(red: 0.92, green: 0.98, blue: 0.94))
        } else if isBusy {
            Text(astrologer.status?.text ?? "Busy")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.29, blue: 0.30))
        } else {
            // Offline: leave empty so the right column collapses around price + buttons.
            Color.clear.frame(height: 0)
        }
    }

    private func badgePill(text: String, textColor: Color, bg: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg, in: Capsule())
    }

    private var priceView: some View {
        HStack(spacing: 6) {
            if hasDiscount, let original = astrologer.originalPrice {
                Text("₹\(original)")
                    .font(.caption2)
                    .strikethrough()
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text("₹\(displayPrice)/min")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: onChat) {
                Text("Connect")
                    .font(.footnote.weight(.semibold))
                    .frame(width: 78, height: 34)
            }
            .buttonStyle(.glass)
            .tint(AppTheme.pinkAccent)

            if isOffline, let onNotify {
                Button(action: onNotify) {
                    Image(systemName: notified ? "bell.fill" : "bell")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(notified ? AppTheme.pinkAccent : .white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular, in: .circle)
            }
        }
    }

    // MARK: - Bottom half

    private var bottomRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            nameAndFeatures
            if !studies.isEmpty || !languages.isEmpty {
                skillsRow
            }
        }
    }

    private var nameAndFeatures: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(astrologer.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if astrologer.premium == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.goldGradient)
                } else if astrologer.verified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
            }
            .layoutPriority(1)

            divider

            HStack(spacing: 8) {
                if let exp = astrologer.experience, exp > 0 {
                    featureItem(icon: "book.closed.fill", text: "\(Int(exp)) Yrs")
                }
                if rating > 0 {
                    featureItem(icon: "star.fill", text: String(format: "%.1f", rating))
                }
                if let chats = astrologer.chats, chats > 0 {
                    featureItem(icon: "message.fill", text: Self.formatCount(chats))
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var skillsRow: some View {
        HStack(spacing: 6) {
            if !studies.isEmpty {
                Text(studies.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            if !studies.isEmpty && !languages.isEmpty {
                divider
            }
            if !languages.isEmpty {
                Text(languages.joined(separator: " • "))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.18))
            .frame(width: 1, height: 14)
    }

    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
            Text(text)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
    }

    /// 1234 → "1.2k", 100000+ → "100k". Matches RN `formatNumber`.
    private static func formatCount(_ n: Int) -> String {
        if n >= 100_000 { return "\(n / 1000)k" }
        if n >= 1_000 {
            let k = Double(n) / 1000.0
            return String(format: k.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fk" : "%.1fk", k)
        }
        return "\(n)"
    }
}
