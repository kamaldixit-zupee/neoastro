import SwiftUI

enum AppTheme {
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

    static let pinkAccent = Color(red: 0.92, green: 0.32, blue: 0.55)
    static let cardCorner: CGFloat = 24
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
