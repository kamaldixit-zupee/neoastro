import SwiftUI

/// Modeled after `zupee-rn-astro/src/screens/home/SearchAstrologer.tsx`:
/// recent astrologers across the top, results list (or empty state) in the
/// middle, and a persistent search bar pinned to the bottom with a Home
/// button on the left and a clear (x) button on the right of the input.
struct SearchView: View {
    /// Called by the home / exit buttons in the bottom search bar. The
    /// parent (`MainTabView`) flips its `selection` back to `.home` so we
    /// land on the Home tab.
    var onClose: () -> Void = {}

    @State private var vm = SearchViewModel()
    @State private var selectedAstrologer: AstrologerAPI?
    @State private var chatConfirmation: AstrologerAPI?
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()
                    // Tap outside any control dismisses the keyboard. Buttons
                    // / cards consume their own taps so this only fires on
                    // empty background space.
                    .contentShape(Rectangle())
                    .onTapGesture { inputFocused = false }

                VStack(spacing: 0) {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
            }
            .navigationDestination(item: $selectedAstrologer) { astrologer in
                AstrologerProfileView(astrologer: astrologer)
            }
            .navigationDestination(item: $chatConfirmation) { astrologer in
                ChatView(astrologer: astrologer)
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .task {
                await vm.loadInitial()
                // small delay so the modal-present animation completes before
                // the keyboard slides up — otherwise SwiftUI sometimes drops
                // the focus request mid-transition.
                try? await Task.sleep(for: .milliseconds(120))
                inputFocused = true
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !vm.query.trimmingCharacters(in: .whitespaces).isEmpty {
            resultsList
        } else if !vm.recentAstrologers.isEmpty {
            recentSearchesSection
        } else if vm.isLoadingInitial {
            VStack {
                Spacer()
                ProgressView().tint(.white).controlSize(.large)
                Spacer()
            }
        } else {
            emptyState
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if vm.searchResults.isEmpty {
                    Text("No astrologers found with that name")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 40)
                } else {
                    ForEach(vm.searchResults) { astrologer in
                        AstrologerCard(
                            astrologer: astrologer,
                            onTap: { handleTap(astrologer) },
                            onChat: {
                                vm.recordTap(astrologer)
                                chatConfirmation = astrologer
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Search")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button("Clear all") { vm.clearRecent() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.pinkAccent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.recentAstrologers) { astrologer in
                        recentChip(astrologer)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .scrollDismissesKeyboard(.interactively)

            Spacer(minLength: 0)
                .contentShape(Rectangle())
                .onTapGesture { inputFocused = false }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.5))
            Text("Search for an astrologer by name")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func recentChip(_ astrologer: AstrologerAPI) -> some View {
        Button { handleTap(astrologer) } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    AvatarView(
                        name: astrologer.name,
                        imageURL: astrologer.imageURL,
                        gradient: AppTheme.avatarPalette(for: astrologer._id),
                        size: 64
                    )

                    Button {
                        vm.clearRecent(astrologer._id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .background(Circle().fill(.black.opacity(0.55)))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                }

                Text(astrologer.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 80)
            }
            .padding(.top, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Button { onClose() } label: {
                Image(systemName: "house.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))

                TextField(
                    "",
                    text: $vm.query,
                    prompt: Text("Search astrologers name").foregroundColor(.white.opacity(0.5))
                )
                .focused($inputFocused)
                .foregroundStyle(.white)
                .tint(AppTheme.pinkAccent)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)

                if !vm.query.isEmpty {
                    Button {
                        vm.query = ""
                        inputFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .glassEffect(.regular, in: .capsule)
            .animation(.smooth(duration: 0.18), value: vm.query.isEmpty)

            Button { onClose() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }

    // MARK: - Actions

    private func handleTap(_ astrologer: AstrologerAPI) {
        vm.recordTap(astrologer)
        selectedAstrologer = astrologer
    }
}

#if DEBUG
#Preview {
    SearchView()
        .previewEnvironment()
}
#endif
