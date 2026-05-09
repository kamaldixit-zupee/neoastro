import SwiftUI

@Observable
@MainActor
final class NotificationCenterViewModel {
    var notifications: [NotificationItem] = []
    var unreadCount: Int = 0
    var isLoading: Bool = false
    var errorMessage: String?
    var clearingAll: Bool = false

    func load() async {
        guard notifications.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        AppLog.info(.api, "VM · notifications refresh start")
        do {
            let result = try await NotificationService.list()
            notifications = result.notifications ?? []
            unreadCount = result.unreadCount ?? 0
            AppLog.info(.api, "VM · notifications refresh ok count=\(notifications.count) unread=\(unreadCount)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.api, "notifications list failed", error: error)
        }
        isLoading = false
    }

    func markRead(_ item: NotificationItem) async {
        guard item.unread, let id = item._id else { return }
        do {
            try await NotificationService.markRead(notificationId: id)
            if let idx = notifications.firstIndex(where: { $0._id == id }) {
                let read = NotificationItem(
                    _id: notifications[idx]._id,
                    title: notifications[idx].title,
                    body: notifications[idx].body,
                    imageUrl: notifications[idx].imageUrl,
                    iconUrl: notifications[idx].iconUrl,
                    type: notifications[idx].type,
                    createdTimestamp: notifications[idx].createdTimestamp,
                    isRead: true,
                    deepLink: notifications[idx].deepLink,
                    category: notifications[idx].category
                )
                notifications[idx] = read
                unreadCount = max(0, unreadCount - 1)
            }
        } catch {
            AppLog.error(.api, "markRead failed", error: error)
        }
    }

    func clear(_ item: NotificationItem) async {
        guard let id = item._id else { return }
        do {
            try await NotificationService.clear(notificationId: id)
            notifications.removeAll { $0._id == id }
            if item.unread { unreadCount = max(0, unreadCount - 1) }
        } catch {
            AppLog.error(.api, "clear notification failed", error: error)
        }
    }

    func clearAll() async {
        clearingAll = true
        do {
            try await NotificationService.clearAll()
            notifications.removeAll()
            unreadCount = 0
        } catch {
            AppLog.error(.api, "clearAll notifications failed", error: error)
        }
        clearingAll = false
    }
}

struct NotificationCenterView: View {
    @State private var vm = NotificationCenterViewModel()
    @State private var confirmClearAll: Bool = false

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
                    if vm.isLoading && vm.notifications.isEmpty {
                        ProgressView().tint(.white).controlSize(.large)
                            .padding(.top, 60)
                    } else if vm.notifications.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.notifications) { item in
                            row(item)
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
        .navigationTitle(vm.unreadCount > 0 ? "Notifications · \(vm.unreadCount)" : "Notifications")
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
                .disabled(vm.notifications.isEmpty || vm.clearingAll)
            }
        }
        .confirmationDialog("Clear all notifications?", isPresented: $confirmClearAll) {
            Button("Clear All", role: .destructive) {
                Task { await vm.clearAll() }
            }
        } message: {
            Text("This removes every notification from your inbox. The action can't be undone.")
        }
        .task { await vm.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.6))
                .padding(20)
                .glassEffect(.regular, in: .circle)
            Text("No notifications yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("We'll let you know when astrologers go online or your wallet changes.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func row(_ item: NotificationItem) -> some View {
        Button {
            Task { await vm.markRead(item) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                avatarView(for: item)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.displayTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Spacer()
                        Text(Self.dateFormatter.localizedString(for: item.date, relativeTo: .now))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    if !item.displayBody.isEmpty {
                        Text(item.displayBody)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(3)
                    }
                }

                if item.unread {
                    Circle()
                        .fill(AppTheme.pinkAccent)
                        .frame(width: 8, height: 8)
                        .offset(y: 6)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(item.unread ? AppTheme.pinkAccent.opacity(0.4) : .white.opacity(0.08),
                        lineWidth: item.unread ? 1 : 1)
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await vm.clear(item) }
            } label: {
                Label("Clear", systemImage: "trash.fill")
            }
        }
    }

    @ViewBuilder
    private func avatarView(for item: NotificationItem) -> some View {
        let url = URL(string: item.iconUrl ?? item.imageUrl ?? "")
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    placeholderIcon(for: item)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .glassEffect(.regular, in: .circle)
        } else {
            placeholderIcon(for: item)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)
        }
    }

    private func placeholderIcon(for item: NotificationItem) -> some View {
        let icon: String = {
            switch (item.type ?? item.category ?? "").lowercased() {
            case let s where s.contains("call"):     return "phone.fill"
            case let s where s.contains("chat"):     return "message.fill"
            case let s where s.contains("payment"):  return "creditcard.fill"
            case let s where s.contains("astro"):    return "sparkles"
            case let s where s.contains("offer"):    return "gift.fill"
            default:                                  return "bell.fill"
            }
        }()
        return Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(AppTheme.goldGradient)
    }
}
