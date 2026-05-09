import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @State private var selectedAstrologer: AstrologerAPI?
    @State private var chatConfirmation: AstrologerAPI?
    @State private var pendingChatAstrologer: AstrologerAPI?
    @Environment(HomeSearchCoordinator.self) private var searchCoordinator
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()

                GeometryReader { geo in
                    let cardHeight = (174.0 / 360.0) * geo.size.width

                    ScrollView {
                        VStack(spacing: 14) {
                            heroBanner
                                .padding(.horizontal, 16)
                                .padding(.top, 4)

                            if vm.isLoading && vm.astrologers.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.top, 40)
                            } else if let error = vm.errorMessage, vm.astrologers.isEmpty {
                                errorView(error)
                            } else if vm.astrologers.isEmpty {
                                emptyView
                            } else {
                                ForEach(vm.astrologers) { astrologer in
                                    AstrologerCard(
                                        astrologer: astrologer,
                                        height: cardHeight,
                                        onTap: { selectedAstrologer = astrologer },
                                        onChat: { chatConfirmation = astrologer }
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .refreshable { await vm.refresh() }
                }
            }
            .navigationTitle("NeoAstro")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $vm.searchText, prompt: "Search astrologers, skills…")
            .searchFocused($searchFocused)
            .navigationDestination(item: $selectedAstrologer) { astrologer in
                AstrologerProfileView(astrologer: astrologer)
            }
            .navigationDestination(item: $pendingChatAstrologer) { astrologer in
                ConsultChatView(astrologer: astrologer)
            }
            .sheet(item: $chatConfirmation) { astrologer in
                ChatConfirmationSheet(
                    astrologer: astrologer,
                    onConfirm: {
                        chatConfirmation = nil
                        pendingChatAstrologer = astrologer
                    },
                    onCancel: { chatConfirmation = nil }
                )
                .presentationDetents([.fraction(0.55), .large])
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden)
            }
            .task { await vm.loadInitial() }
            .onChange(of: searchCoordinator.requestFocusToken) { _, _ in
                searchFocused = true
            }
        }
    }

    private var heroBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(AppTheme.goldGradient)
                .padding(12)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text("First chat free")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Connect with verified astrologers now")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await vm.refresh() } }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
                .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
            Text("No astrologers found")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
