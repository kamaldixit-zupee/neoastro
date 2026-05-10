import SwiftUI

/// Step 4: present the astrologer's answer plus a row of recommended
/// astrologers the user can engage with for a paid follow-up.
struct FreeAskAnswersView: View {
    let onClose: () -> Void
    let onPickAstrologer: (String) -> Void  // astroId

    @Environment(RealtimeStore.self) private var realtime

    private var answer: FreeAskAnsweredPayload? { realtime.freeAskAnswer }

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    if let answer {
                        questionCard(answer)
                        answerCard(answer)
                        if let recommended = answer.recommendedAstrologers, !recommended.isEmpty {
                            recommendedSection(recommended, viewAll: answer.viewAllText)
                        }
                        if let nextAskText = answer.askNextOneInText, !nextAskText.isEmpty {
                            nextAskCard(nextAskText)
                        }
                    } else {
                        ProgressView().tint(.white).controlSize(.large).padding(.top, 40)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Your Answer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { onClose() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            // Mark the answer as viewed (for unread-decrement on the server).
            guard let astroId = answer?.astrologerId else { return }
            Task {
                await NeoAstroSocket.shared.emit(.answerViewd, payload: AnswerViewedPayload(astroId: astroId))
            }
        }
    }

    // MARK: - Sections

    private func questionCard(_ answer: FreeAskAnsweredPayload) -> some View {
        let q = answer.questionText ?? realtime.freeAskLocalSubmission?.questionText ?? ""
        return VStack(alignment: .leading, spacing: 6) {
            Text("YOU ASKED")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(1)
            Text(q)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func answerCard(_ answer: FreeAskAnsweredPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(
                    name: answer.astrologerName ?? "Astrologer",
                    imageURL: answer.astrologerImage.flatMap(URL.init(string:)),
                    gradient: answer.astrologerId.map(AppTheme.avatarPalette(for:)) ?? AppTheme.primaryAvatarPalette,
                    size: 48
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(answer.astrologerName ?? "Astrologer")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Answered just now")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
            }

            if let body = answer.answer, !body.isEmpty {
                Text(body)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Open the chat with this astrologer to read their full answer.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if let astroId = answer.astrologerId {
                Button {
                    onPickAstrologer(astroId)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                        Text("Chat with this astrologer")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(AppTheme.pinkAccent)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }

    private func recommendedSection(_ astrologers: [FreeAskAstrologerLite], viewAll: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Other astrologers")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if let viewAll, !viewAll.isEmpty {
                    Text(viewAll)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.pinkAccent)
                }
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(astrologers) { astro in
                        astroChip(astro)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func astroChip(_ astro: FreeAskAstrologerLite) -> some View {
        Button {
            if let id = astro._id { onPickAstrologer(id) }
        } label: {
            VStack(spacing: 6) {
                AvatarView(
                    name: astro.displayName,
                    imageURL: astro.imageURL,
                    gradient: AppTheme.avatarPalette(for: astro.id),
                    size: 56
                )
                Text(astro.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if astro.displayPrice > 0 {
                    Text("₹\(astro.displayPrice)/min")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.goldGradient)
                }
            }
            .padding(10)
            .frame(width: 100)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func nextAskCard(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .foregroundStyle(AppTheme.goldGradient)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }
}
