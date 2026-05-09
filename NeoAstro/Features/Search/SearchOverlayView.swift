import SwiftUI

struct SearchOverlayView: View {
    @State private var query: String = ""
    @State private var results: [AstrologerAPI] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedAstrologer: AstrologerAPI?
    @State private var searchTask: Task<Void, Never>?

    private let categories: [(label: String, icon: String)] = [
        ("Vedic", "moon.stars.fill"),
        ("Tarot", "rectangle.stack.fill"),
        ("Numerology", "number"),
        ("Vastu", "house.fill"),
        ("KP", "sparkles"),
        ("Lal Kitab", "book.fill"),
        ("Reiki", "leaf.fill"),
        ("Palmistry", "hand.raised.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if query.isEmpty {
                            categorySection
                            trendingSection
                        } else {
                            resultsSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Search")
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $query, prompt: "Search astrologers, skills…")
            .onChange(of: query) { _, _ in scheduleSearch() }
            .navigationDestination(item: $selectedAstrologer) { astrologer in
                ChatView(astrologer: astrologer)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                ForEach(categories, id: \.label) { cat in
                    Button { query = cat.label } label: {
                        HStack(spacing: 8) {
                            Image(systemName: cat.icon)
                                .foregroundStyle(AppTheme.goldGradient)
                            Text(cat.label)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                }
            }
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested searches")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(["Career", "Love & Relationships", "Health", "Finance", "Marriage"], id: \.self) { tag in
                Button { query = tag } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.7))
                        Text(tag)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(results.isEmpty ? "No results" : "\(results.count) result\(results.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            ForEach(results) { astro in
                Button { selectedAstrologer = astro } label: {
                    HStack(spacing: 12) {
                        AvatarView(name: astro.name, imageURL: astro.imageURL, size: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(astro.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(astro.qualificationText ?? astro.qualification ?? "Astrologer")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            if let price = astro.price, price > 0 {
                                Text("₹\(Int(price))/min")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppTheme.goldGradient)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
            }
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            isLoading = true
            errorMessage = nil
            do {
                results = try await AstrologerService.search(query: trimmed)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }
}
