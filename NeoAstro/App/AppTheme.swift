import SwiftUI
import UIKit

enum AppTheme {

    // MARK: - Gradients

    static let cosmicGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.02, blue: 0.18),
            Color(red: 0.18, green: 0.05, blue: 0.32),
            Color(red: 0.42, green: 0.12, blue: 0.45),
            Color(red: 0.78, green: 0.32, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.85, blue: 0.45),
            Color(red: 0.95, green: 0.62, blue: 0.30)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Wallet balance hero card gradient. Keep glass on top so it refracts
    /// this gradient instead of plain color.
    static let balanceCardGradient = LinearGradient(
        colors: [
            Color(red: 0.45, green: 0.04, blue: 0.72).opacity(0.55),
            Color(red: 0.97, green: 0.14, blue: 0.52).opacity(0.35)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Colors

    static let pinkAccent = Color(red: 0.92, green: 0.32, blue: 0.55)

    /// Opaque content surface for body-text containers (terms, helpdesk articles,
    /// horoscope long reads). Adapts to light / dark.
    static let surface: Color = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.05, blue: 0.18, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.95, blue: 0.99, alpha: 1.0)
    })

    // MARK: - Spacing & shape tokens

    static let cardCorner: CGFloat = 24
    static let tightCorner: CGFloat = 12
    static let sectionSpacing: CGFloat = 18
    static let cardPadding: CGFloat = 14

    // MARK: - Avatar palettes

    /// Reusable ribbon palettes for `AvatarView`'s gradient backdrop.
    private static let avatarPalettes: [[String]] = [
        ["#7B2CBF", "#FF8FAB"],
        ["#3A86FF", "#8338EC"],
        ["#F72585", "#B5179E"],
        ["#06A77D", "#3A86FF"],
        ["#FFB703", "#FB8500"],
        ["#7209B7", "#F72585"]
    ]

    /// Primary brand palette — used when no per-entity seed is available.
    static let primaryAvatarPalette: [String] = ["#7B2CBF", "#F72585"]

    /// Deterministically picks one of the avatar palettes from a seed
    /// (typically an astrologer / user id) so the same entity always renders
    /// with the same backdrop.
    static func avatarPalette(for seed: String) -> [String] {
        guard !avatarPalettes.isEmpty else { return primaryAvatarPalette }
        let i = abs(seed.hashValue) % avatarPalettes.count
        return avatarPalettes[i]
    }
}

struct CosmicBackground: View {
    var body: some View {
        ZStack {
            AppTheme.cosmicGradient.ignoresSafeArea()
            StarsView()
                .ignoresSafeArea()
                .opacity(0.6)
        }
    }
}

struct StarsView: View {
    private let stars: [Star] = (0..<60).map { _ in Star.random() }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: geo.size.width * star.x,
                                  y: geo.size.height * star.y)
                        .opacity(star.opacity)
                }
            }
        }
    }

    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double

        static func random() -> Star {
            Star(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                size: .random(in: 1...2.5),
                opacity: .random(in: 0.3...0.9)
            )
        }
    }
}
