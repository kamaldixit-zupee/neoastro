import SwiftUI

struct AstrologerProfileView: View {
    let astrologer: AstrologerAPI

    @Environment(\.dismiss) private var dismiss
    @Environment(RealtimeStore.self) private var realtime
    @State private var vm: AstrologerProfileViewModel
    @State private var goToChat: Bool = false
    @State private var showStories: Bool = false
    @State private var storyIndex: Int = 0

    init(astrologer: AstrologerAPI) {
        self.astrologer = astrologer
        _vm = State(initialValue: AstrologerProfileViewModel(astrologer: astrologer))
    }

    private var isOnline: Bool {
        if let chatStatus = realtime.presence[astrologer._id]?.chatStatus {
            return chatStatus.uppercased() == "ONLINE"
        }
        if let state = astrologer.status?.state { return state == "ONLINE" }
        return astrologer.isActive ?? false
    }

    private var waitTimeMinutes: Int? {
        realtime.presence[astrologer._id]?.waitTime
    }

    private var palette: [String] { AppTheme.avatarPalette(for: astrologer._id) }

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: 14) {
                    profileHeader
                    if !vm.stories.isEmpty {
                        storiesCarousel
                    }
                    if let rating = displayRating, rating > 0 {
                        ratingRow(rating)
                    }
                    if !isOnline {
                        notifyMeCard
                    }
                    aboutMeSection
                    if let bio = displayBio, !bio.isEmpty {
                        bioSection(bio)
                    }
                    if !vm.educations.isEmpty {
                        educationSection
                    }
                    if !vm.reviews.isEmpty || vm.isLoadingReviews {
                        reviewsSection
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
                Button { goToChat = true } label: {
                    Image(systemName: "message.fill")
                        .foregroundStyle(.white)
                }
            }
        }
        .navigationDestination(isPresented: $goToChat) {
            ChatView(astrologer: astrologer)
        }
        .fullScreenCover(isPresented: $showStories) {
            AstrologerStoriesView(
                astrologerName: astrologer.name,
                stories: vm.stories,
                selectedIndex: $storyIndex
            )
        }
        .task { await vm.load() }
    }

    private var displayRating: Double? {
        if vm.averageRating > 0 { return vm.averageRating }
        return astrologer.ratings
    }

    private var displayBio: String? {
        if let bio = vm.profileDetail?.bio, !bio.isEmpty { return bio }
        return astrologer.bio
    }

    // MARK: - Profile header

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
                    gradient: palette,
                    size: 110
                )
                .grayscale(isOnline ? 0 : 0.5)
                .overlay(
                    Circle()
                        .stroke(isOnline ? .green : Color.white.opacity(0.3), lineWidth: 3)
                        .padding(-6)
                )

                if isOnline {
                    statusPill(text: "Online", color: .green)
                        .offset(y: 70)
                } else if let mins = waitTimeMinutes, mins > 0 {
                    statusPill(text: "Wait ~\(mins) min", color: .orange)
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

    private func statusPill(text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.25), in: Capsule())
        .glassEffect(.regular, in: .capsule)
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

    // MARK: - Stories

    private var storiesCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stories")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(vm.stories.enumerated()), id: \.element.id) { idx, story in
                        Button {
                            storyIndex = idx
                            showStories = true
                        } label: {
                            storyThumb(story)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func storyThumb(_ story: AstrologerStory) -> some View {
        ZStack {
            Circle()
                .stroke(AppTheme.goldGradient, lineWidth: 2)
                .frame(width: 78, height: 78)

            Group {
                if let url = story.thumbURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            Image(systemName: "photo.fill")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                } else {
                    Image(systemName: "photo.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())

            if story.isVideo {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.45), in: Circle())
            }
        }
    }

    // MARK: - Notify me

    @ViewBuilder
    private var notifyMeCard: some View {
        let state = vm.notifyState
        HStack(spacing: 12) {
            Image(systemName: state == .subscribed ? "bell.badge.fill" : "bell.fill")
                .font(.title3)
                .foregroundStyle(state == .subscribed ? .green : AppTheme.goldGradient)
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(notifyTitle(state: state))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(notifySubtitle(state: state))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }

            Spacer()

            if state == .requesting {
                ProgressView().tint(.white)
            } else if state != .subscribed {
                Button("Notify me") { vm.notifyMeWhenOnline() }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .buttonStyle(.glass)
                    .tint(AppTheme.pinkAccent)
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func notifyTitle(state: AstrologerProfileViewModel.NotifyState) -> String {
        switch state {
        case .subscribed: "We'll let you know"
        case .requesting: "Setting up reminder…"
        case .failed: "Couldn't subscribe"
        case .idle: "\(astrologer.name) is offline"
        }
    }

    private func notifySubtitle(state: AstrologerProfileViewModel.NotifyState) -> String {
        switch state {
        case .subscribed: "You'll get a push when this astrologer comes online."
        case .requesting: "Talking to the server…"
        case .failed(let msg): msg
        case .idle: "Subscribe to get a push when they're back."
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

            if vm.totalReviews > 0 {
                Text("(\(vm.totalReviews))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
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

    // MARK: - About me

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

    // MARK: - Education

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Education & Certifications")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(Array(vm.educations.enumerated()), id: \.element.id) { idx, edu in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "graduationcap.fill")
                            .font(.callout)
                            .foregroundStyle(AppTheme.goldGradient)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: .rect(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            if let title = edu.title {
                                Text(title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            if let institution = edu.institution {
                                Text(institution)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            if let year = edu.year {
                                Text(year)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }

                        Spacer()
                    }
                    .padding(14)

                    if idx < vm.educations.count - 1 {
                        Divider().background(.white.opacity(0.08)).padding(.leading, 56)
                    }
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Reviews

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Reviews")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if vm.isLoadingReviews && vm.reviews.isEmpty {
                    ProgressView().tint(.white)
                }
            }

            if vm.reviews.isEmpty && !vm.isLoadingReviews {
                Text("No reviews yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.reviews.prefix(5)) { review in
                        reviewRow(review)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static let reviewDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private func reviewRow(_ review: AstrologerReview) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(
                name: review.displayName,
                imageURL: review.userImage.flatMap(URL.init(string:)),
                gradient: AppTheme.avatarPalette(for: review.id),
                size: 36
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(review.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: i < review.displayRating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                if let comment = review.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(4)
                }
                Text(Self.reviewDateFormatter.string(from: review.date))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
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
