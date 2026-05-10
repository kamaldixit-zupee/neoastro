import SwiftUI

struct AstrologerProfileView: View {
    let astrologer: AstrologerAPI

    @Environment(\.dismiss) private var dismiss
    @State private var goToChat: Bool = false

    private var isOnline: Bool {
        if let state = astrologer.status?.state { return state == "ONLINE" }
        return astrologer.isActive ?? false
    }

    private var gradientPalette: [String] {
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

            ScrollView {
                VStack(spacing: 14) {
                    profileHeader
                    if let rating = astrologer.ratings, rating > 0 {
                        ratingRow(rating)
                    }
                    aboutMeSection
                    if let bio = astrologer.bio, !bio.isEmpty {
                        bioSection(bio)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()
                consultationBottomBar
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "message.fill")
                        .foregroundStyle(.white)
                }
            }
        }
        .navigationDestination(isPresented: $goToChat) {
            ChatView(astrologer: astrologer)
        }
    }

    // MARK: - Profile header (avatar + name + meta)

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 130, height: 130)
                    .blur(radius: 28)
                    .opacity(0.55)

                AvatarView(
                    name: astrologer.name,
                    imageURL: astrologer.imageURL,
                    gradient: gradientPalette,
                    size: 110
                )
                .grayscale(isOnline ? 0 : 0.5)
                .overlay(
                    Circle()
                        .stroke(isOnline ? .green : Color.white.opacity(0.3), lineWidth: 3)
                        .padding(-6)
                )

                if isOnline {
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("Online")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.25), in: Capsule())
                    .glassEffect(.regular, in: .capsule)
                    .offset(y: 70)
                }
            }
            .padding(.top, 8)

            HStack(spacing: 6) {
                Text(astrologer.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                if astrologer.verified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.body)
                        .foregroundStyle(AppTheme.goldGradient)
                }
            }

            if let qualification = astrologer.qualificationText ?? astrologer.qualification ?? astrologer.heading {
                Text(qualification)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            metaInfoRow
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder
    private var metaInfoRow: some View {
        let chips: [(icon: String, text: String)] = [
            astrologer.experience.map { ("book.fill", "\(Int($0))y experience") },
            astrologer.location.map { ("location.fill", $0) },
            astrologer.chats.map { ("bubble.left.and.bubble.right.fill", "\($0)+ chats") }
        ].compactMap { $0 }

        if !chips.isEmpty {
            HStack(spacing: 8) {
                ForEach(chips, id: \.text) { chip in
                    HStack(spacing: 4) {
                        Image(systemName: chip.icon)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.goldGradient)
                        Text(chip.text)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
                }
            }
        }
    }

    // MARK: - Rating

    private func ratingRow(_ rating: Double) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", rating))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            if let trust = astrologer.trustText, !trust.isEmpty {
                Text(trust.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: ""))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    // MARK: - About me (skills + languages)

    @ViewBuilder
    private var aboutMeSection: some View {
        let hasSkills = !(astrologer.studies?.isEmpty ?? true)
        let hasLanguages = !(astrologer.languages?.isEmpty ?? true)

        if hasSkills || hasLanguages {
            VStack(alignment: .leading, spacing: 12) {
                Text("About Me")
                    .font(.headline)
                    .foregroundStyle(.white)

                VStack(spacing: 0) {
                    if let studies = astrologer.studies, !studies.isEmpty {
                        aboutRow(
                            icon: "book.fill",
                            label: "Skills",
                            value: studies.map { $0.capitalized }.joined(separator: ", ")
                        )
                        if hasLanguages {
                            Divider().background(.white.opacity(0.08)).padding(.leading, 56)
                        }
                    }

                    if let languages = astrologer.languages, !languages.isEmpty {
                        aboutRow(
                            icon: "globe",
                            label: "Languages",
                            value: languages.joined(separator: ", ")
                        )
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func aboutRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(14)
    }

    // MARK: - Bio

    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.headline)
                .foregroundStyle(.white)

            Text(bio)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Bottom consultation bar

    private var consultationBottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                priceBlock

                Button {
                    goToChat = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                        Text("Start Chat")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(AppTheme.pinkAccent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(.ultraThinMaterial.opacity(0.4))
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var priceBlock: some View {
        let price = astrologer.displayPrice
        let original = astrologer.originalPrice

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("₹\(price)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.goldGradient)
                if let original {
                    Text("₹\(original)")
                        .font(.caption2)
                        .strikethrough()
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Text("per minute")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
