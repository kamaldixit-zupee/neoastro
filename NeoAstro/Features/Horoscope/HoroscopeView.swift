import SwiftUI

struct HoroscopeView: View {
    @State private var vm = HoroscopeViewModel()
    @State private var selectedAstrologer: AstrologerAPI?

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        typePicker
                        contentSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Horoscope")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedAstrologer) { astro in
                ChatView(astrologer: astro)
            }
            .task { await vm.load() }
        }
    }

    private var typePicker: some View {
        HStack(spacing: 8) {
            ForEach(HoroscopeService.HoroscopeType.allCases) { t in
                Button {
                    Task { await vm.change(type: t) }
                } label: {
                    Text(t.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.glass)
                .tint(vm.type == t ? AppTheme.pinkAccent : .white)
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var contentSection: some View {
        if vm.isLoading && vm.horoscope == nil {
            VStack(spacing: 12) {
                ProgressView().tint(.white).controlSize(.large)
                Text("Reading the cosmos…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        } else if let error = vm.errorMessage, vm.horoscope == nil {
            errorView(error)
        } else if let h = vm.horoscope {
            heroCard(h)
            if let entities = h.luckyEntities, !entities.isEmpty {
                luckySection(entities)
            }
            if let cards = h.horoscopeCards, !cards.isEmpty {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    horoscopeCard(card)
                }
            }
            if let astro = h.horoscopeAstrologer {
                astrologerCTA(astro)
            }
        }
    }

    private func heroCard(_ h: Horoscope) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 130, height: 130)
                    .blur(radius: 28)
                    .opacity(0.5)

                if let urlString = h.zodiacSignUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundStyle(AppTheme.goldGradient)
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .glassEffect(.regular, in: .circle)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(AppTheme.goldGradient)
                        .frame(width: 110, height: 110)
                        .glassEffect(.regular, in: .circle)
                }
            }

            VStack(spacing: 6) {
                Text(h.zodiacName ?? "Your Horoscope")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                if let title = h.horoscopeTitle, !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }

                if let cosmic = h.cosmicPositionText, !cosmic.isEmpty {
                    Text(cosmic)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func luckySection(_ entities: [Horoscope.LuckyEntity]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lucky Today")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                ForEach(entities, id: \.self) { entity in
                    HStack(spacing: 8) {
                        if let code = entity.code, code.hasPrefix("#") {
                            Circle()
                                .fill(Color(hex: code))
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: iconFor(entity: entity.entity))
                                .foregroundStyle(AppTheme.goldGradient)
                        }
                        Text(entity.text ?? "")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: .capsule)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func iconFor(entity: String?) -> String {
        switch entity?.lowercased() {
        case "color": "paintpalette.fill"
        case "number": "number"
        case "stone": "diamond.fill"
        case "day": "calendar"
        default: "sparkles"
        }
    }

    private func horoscopeCard(_ card: Horoscope.HoroscopeCard) -> some View {
        let sentimentColor: Color = {
            switch card.sentiment?.lowercased() {
            case "positive": return .green
            case "negative": return .red
            default: return .yellow
            }
        }()

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let iconUrl = card.iconUrl, let url = URL(string: iconUrl) {
                    AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: {
                        Image(systemName: "sparkles").foregroundStyle(sentimentColor)
                    }
                    .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "sparkles")
                        .foregroundStyle(sentimentColor)
                }

                Text(card.title ?? "Insight")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()
            }

            if let summary = card.summary, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            if let descriptions = card.description {
                ForEach(Array(descriptions.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(sentimentColor.opacity(0.4), lineWidth: 1)
        )
    }

    private func astrologerCTA(_ astro: AstrologerAPI) -> some View {
        Button { selectedAstrologer = astro } label: {
            HStack(spacing: 12) {
                AvatarView(name: astro.name, imageURL: astro.imageURL, size: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Talk to \(astro.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(astro.qualificationText ?? astro.qualification ?? "Astrologer")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "message.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .glassEffect(.regular, in: .circle)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await vm.refresh() } }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

#Preview {
    HoroscopeView()
        .previewEnvironment()
}
