import SwiftUI

struct AvatarView: View {
    let name: String
    var imageURL: URL? = nil
    var gradient: [String] = ["#7B2CBF", "#F72585"]
    var size: CGFloat = 64

    private var initials: String {
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return chars.map { String($0) }.joined().uppercased()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradient.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        Text(initials)
                            .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
    }
}
