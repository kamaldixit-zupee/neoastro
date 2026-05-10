import SwiftUI

struct HomeView: View {
    @State private var vm = HomeViewModel()
    @State private var selectedAstrologer: AstrologerAPI?
    @State private var chatConfirmation: AstrologerAPI?
    @State private var pendingChatAstrologer: AstrologerAPI?
    @State private var showNotifications: Bool = false
    @State private var showFreeAsk: Bool = false
    @State private var showFreeChat: Bool = false
    @Environment(HomeSearchCoordinator.self) private var searchCoordinator
    @Environment(RealtimeStore.self) private var realtime
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

                            freeActionsRow
                                .padding(.horizontal, 16)

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        Image(systemName: "bell.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
            }
            .searchable(text: $vm.searchText, prompt: "Search astrologers, skills…")
            .searchFocused($searchFocused)
            .navigationDestination(item: $selectedAstrologer) { astrologer in
                AstrologerProfileView(astrologer: astrologer)
            }
            .navigationDestination(item: $pendingChatAstrologer) { astrologer in
                ChatView(astrologer: astrologer)
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationCenterView()
            }
            .sheet(isPresented: $showFreeAsk) {
                FreeAskFlow(onClose: { showFreeAsk = false }, onPickAstrologer: handleFreeAskAstrologerPick)
            }
            .sheet(isPresented: $showFreeChat) {
                FreeChatFlow(onClose: { showFreeChat = false }, onAssigned: handleFreeChatAssigned)
            }
            .sheet(item: $chatConfirmation) { astrologer in
                ChatConfirmationSheet(
                    astrologer: astrologer,
                    onConfirm: {
                        chatConfirmation = nil
                        startChat(with: astrologer)
                    },
                    onCancel: { chatConfirmation = nil }
                )
                .presentationDetents([.fraction(0.55), .large])
                .presentationDragIndicator(.visible)
            }
            .task { await vm.loadInitial() }
            .onChange(of: searchCoordinator.requestFocusToken) { _, _ in
                searchFocused = true
            }
        }
    }

    private var freeActionsRow: some View {
        HStack(spacing: 10) {
            freeActionTile(
                icon: "sparkles",
                title: "Free Question",
                subtitle: "One free answer",
                action: {
                    realtime.resetFreeAsk()
                    showFreeAsk = true
                }
            )
            freeActionTile(
                icon: "message.badge.filled.fill",
                title: "Free Chat",
                subtitle: "First chat on us",
                action: {
                    realtime.resetFreeChat()
                    showFreeChat = true
                }
            )
        }
    }

    private func freeActionTile(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppTheme.goldGradient)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    /// Free Ask → user picked an astrologer → close the sheet, look up the
    /// astrologer in the loaded list, and route into the chat-confirmation
    /// sheet for the per-minute consultation.
    private func handleFreeAskAstrologerPick(_ astroId: String) {
        showFreeAsk = false
        if let astrologer = vm.allAstrologers.first(where: { $0._id == astroId }) {
            chatConfirmation = astrologer
        } else {
            AppLog.warn(.chat, "free ask pick · astrologer \(astroId) not in home list")
        }
    }

    /// Free Chat assigned an astrologer. Find them in the home list and
    /// push directly into ChatView (the realtime store will fill in the
    /// active chat once `CHAT_STARTED` arrives). If not in the list, fall
    /// back to closing — the user will see the chat in their notifications.
    private func handleFreeChatAssigned(_ astroId: String) {
        showFreeChat = false
        if let astrologer = vm.allAstrologers.first(where: { $0._id == astroId }) {
            pendingChatAstrologer = astrologer
        } else {
            AppLog.warn(.chat, "free chat assigned · astrologer \(astroId) not in home list")
        }
    }

    /// Confirm-sheet → emit INITIATE_CHAT → push ChatView. The chat view
    /// itself waits on `realtime.activeChat` to populate via CHAT_STARTED.
    private func startChat(with astrologer: AstrologerAPI) {
        AppLog.info(.chat, "VM · INITIATE_CHAT astroId=\(astrologer._id)")
        Task {
            await NeoAstroSocket.shared.emit(
                .initiateChat,
                payload: InitiateChatPayload(astroId: astrologer._id)
            )
        }
        pendingChatAstrologer = astrologer
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
