import SwiftUI

/// Reusable Liquid Glass banner for in-app nudges (e.g. "Astrologer just came
/// online", "Recharge to keep chatting"). Drop one at the top of any feature
/// screen; tap fires `onAction`. Fetched via
/// `NotificationService.nudges(forScreen:)` and reported back with
/// `NotificationService.markNudgeShown(_:)`.
struct NudgeBanner: View {
    let nudge: NudgeItem
    var onAction: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                if let title = nudge.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                if let subtitle = nudge.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            if let cta = nudge.cta?.displayText, !cta.isEmpty {
                Button {
                    onAction?()
                    Task {
                        if let id = nudge._id {
                            try? await NotificationService.markNudgeShown(id)
                        }
                    }
                } label: {
                    Text(cta)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
            }

            if onDismiss != nil {
                Button {
                    onDismiss?()
                    Task {
                        if let id = nudge._id {
                            try? await NotificationService.markNudgeShown(id)
                        }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var iconView: some View {
        if let urlString = nudge.iconUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().padding(6)
                default:
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(AppTheme.goldGradient)
                }
            }
            .frame(width: 36, height: 36)
            .glassEffect(.regular, in: .circle)
        } else {
            Image(systemName: "bell.badge.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .circle)
        }
    }
}
