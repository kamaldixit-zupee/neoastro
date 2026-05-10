import SwiftUI

/// Step 1 of the Free Ask flow: pick a category for the question.
struct SelectFreeQuestionView: View {
    let onSelect: (FreeAskCategory) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    header

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(FreeAskCategory.allCases) { cat in
                            tile(for: cat)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Free Question")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(AppTheme.goldGradient)
                .padding(14)
                .glassEffect(.regular, in: .circle)

            Text("Ask one free question")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("Pick a topic — multiple astrologers will respond. Pick the answer you trust most.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    private func tile(for category: FreeAskCategory) -> some View {
        Button {
            onSelect(category)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.goldGradient)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular, in: .circle)

                Text(category.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }
}
