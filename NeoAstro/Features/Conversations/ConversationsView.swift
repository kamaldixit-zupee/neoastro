import SwiftUI

/// Past + active chats list. Tap a row → `ChatHistoryView` for read-only
/// access to the conversation. Active conversations also expose a "Continue
/// chat" CTA inside the history view that re-initiates via `INITIATE_CHAT`.
struct ConversationsView: View {
    @State private var vm = ConversationsViewModel()
    @State private var confirmClearAll: Bool = false
    @State private var selectedConversation: ConversationSummary?

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: 8) {
                    if vm.isLoading && vm.conversations.isEmpty {
                        ProgressView().tint(.white).controlSize(.large)
                            .padding(.top, 60)
                    } else if vm.conversations.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.conversations) { conv in
                            row(conv)
                        }
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .refreshable { await vm.refresh() }
        }
        .navigationTitle("Conversations")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    confirmClearAll = true
                } label: {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .disabled(vm.conversations.isEmpty || vm.isClearingAll)
            }
        }
        .navigationDestination(item: $selectedConversation) { conv in
            ChatHistoryView(conversation: conv)
        }
        .confirmationDialog("Clear all conversations?", isPresented: $confirmClearAll) {
            Button("Clear All", role: .destructive) {
                Task { await vm.clearAll() }
            }
        } message: {
            Text("This permanently removes every chat history. Active sessions are not affected.")
        }
        .task { await vm.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.6))
                .padding(20)
                .glassEffect(.regular, in: .circle)
            Text("No conversations yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Start a chat with an astrologer from the Home tab and it will show up here.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func row(_ conv: ConversationSummary) -> some View {
        Button {
            selectedConversation = conv
        } label: {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(
                    name: conv.astrologerName ?? "Astrologer",
                    imageURL: conv.astrologerImage.flatMap(URL.init(string:)),
                    gradient: AppTheme.avatarPalette(for: conv.astroId ?? conv.id),
                    size: 44
                )
                .overlay(alignment: .bottomTrailing) {
                    if conv.isActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(conv.astrologerName ?? "Astrologer")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(Self.dateFormatter.localizedString(for: conv.date, relativeTo: .now))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    HStack(spacing: 6) {
                        Text(conv.displayLastMessage)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)
                        Spacer()
                        if let unread = conv.unreadCount, unread > 0 {
                            Text("\(unread)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(AppTheme.pinkAccent, in: Capsule())
                        }
                    }
                }
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(conv.isActive ? .green.opacity(0.35) : .white.opacity(0.08), lineWidth: 1)
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await vm.delete(conv) }
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}
