import SwiftUI

struct AccountView: View {
    @Environment(AuthViewModel.self) private var auth
    @State private var vm = AccountViewModel()
    @State private var confirmDelete = false
    @State private var confirmLogout = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        profileHeader
                            .padding(.top, 16)

                        if !vm.settings.isEmpty {
                            ForEach(vm.settings) { widget in
                                widgetSection(widget)
                            }
                        } else if vm.isLoading {
                            ProgressView().tint(.white)
                                .padding(.top, 20)
                        }

                        if let error = vm.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        destructiveActions
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Account")
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showEditProfile) {
                if let profile = vm.profile {
                    EditProfileView(profile: profile, onSaved: { Task { await vm.refresh() } })
                }
            }
            .alert("Logout?", isPresented: $confirmLogout) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) { auth.logout() }
            } message: {
                Text("You'll need to verify your number again.")
            }
            .alert("Delete Account?", isPresented: $confirmDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        let ok = await vm.deleteAccount()
                        if ok { auth.logout() }
                    }
                }
            } message: {
                Text("This permanently removes your data and cannot be undone.")
            }
            .task { await vm.load() }
        }
    }

    private var displayName: String {
        vm.profile?.name ?? userBlockUsername() ?? "NeoAstro User"
    }

    private var displayPhone: String {
        let stored = vm.profile?.phone ?? auth.mobileNumber
        return stored.isEmpty ? "" : "+91 \(stored)"
    }

    /// If the API returned a profile widget, use the username from it.
    private func userBlockUsername() -> String? {
        for widget in vm.settings {
            if widget.widgetType == "USER_BLOCK" || widget.widgetType == "PROFILE_HEADER" {
                if let name = widget.items?.first?.username, !name.isEmpty { return name }
            }
        }
        return nil
    }

    private func userBlockImageURL() -> URL? {
        for widget in vm.settings {
            if widget.widgetType == "USER_BLOCK" || widget.widgetType == "PROFILE_HEADER" {
                if let url = widget.items?.first?.iconURL { return url }
            }
        }
        return nil
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 110, height: 110)
                    .blur(radius: 22)
                    .opacity(0.4)

                AvatarView(
                    name: displayName,
                    imageURL: userBlockImageURL() ?? vm.profile?.profilePictureUrl.flatMap(URL.init(string:)),
                    gradient: ["#7B2CBF", "#F72585"],
                    size: 100
                )
            }

            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                if !displayPhone.isEmpty {
                    Text(displayPhone)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            HStack(spacing: 10) {
                if let zodiac = vm.profile?.zodiacName ?? TokenStore.shared.zodiacName {
                    pill(icon: "sparkles", text: zodiac)
                }
                pill(icon: "star.fill", text: "Member")
            }

            Button { showEditProfile = true } label: {
                Text("Edit Profile")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
            .tint(AppTheme.pinkAccent)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.goldGradient)
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }

    private func widgetSection(_ widget: UserSettingsWidget) -> some View {
        let visibleItems = (widget.items ?? []).filter { $0.isVisible && !($0.title?.isEmpty ?? true || ($0.cta == nil && $0.subTitle == nil && $0.description == nil)) }
        let renderableItems = (widget.items ?? []).filter { item in
            guard item.isVisible else { return false }
            // skip pure profile-header items (already shown above)
            if (widget.widgetType == "USER_BLOCK" || widget.widgetType == "PROFILE_HEADER") && item.username != nil {
                return false
            }
            // need either a title or subtitle or cta to be worth rendering as a row
            return (item.title != nil) || (item.subTitle != nil) || (item.cta?.displayText != nil)
        }

        return VStack(spacing: 8) {
            if let header = widgetHeader(for: widget.widgetType) {
                Text(header)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
            }

            VStack(spacing: 6) {
                ForEach(renderableItems, id: \.stableID) { item in
                    settingsRow(item)
                }
            }

            // suppress empty trailing pad
            if renderableItems.isEmpty && visibleItems.isEmpty { EmptyView() }
        }
    }

    private func widgetHeader(for type: String?) -> String? {
        guard let t = type else { return nil }
        switch t.uppercased() {
        case "USER_BLOCK", "PROFILE_HEADER": return nil
        case "ACCOUNT": return "Account"
        case "PAYMENTS": return "Payments"
        case "SUPPORT", "HELP": return "Help & Support"
        case "PREFERENCES": return "Preferences"
        case "ABOUT", "LEGAL": return "About"
        default: return t.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func settingsRow(_ item: UserSettingsItem) -> some View {
        Button {
            handleCTA(item.cta)
        } label: {
            HStack(spacing: 14) {
                rowIcon(for: item)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title ?? item.cta?.displayText ?? "")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let subtitle = item.subTitle ?? item.description, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }

                Spacer()

                if let tertiary = item.tertiaryTitle, !tertiary.isEmpty {
                    Text(tertiary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func rowIcon(for item: UserSettingsItem) -> some View {
        Group {
            if let url = item.iconURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit().padding(6)
                    default:
                        Image(systemName: defaultIconName(for: item))
                            .foregroundStyle(.white)
                    }
                }
            } else {
                Image(systemName: defaultIconName(for: item))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 36, height: 36)
        .glassEffect(.regular, in: .circle)
    }

    private func defaultIconName(for item: UserSettingsItem) -> String {
        let key = (item.id ?? item.title ?? "").lowercased()
        if key.contains("wallet") || key.contains("payment") { return "creditcard.fill" }
        if key.contains("notification") { return "bell.fill" }
        if key.contains("language") { return "globe" }
        if key.contains("help") || key.contains("support") { return "questionmark.circle.fill" }
        if key.contains("logout") { return "rectangle.portrait.and.arrow.right" }
        if key.contains("delete") { return "trash.fill" }
        if key.contains("privacy") { return "lock.fill" }
        if key.contains("terms") { return "doc.text.fill" }
        if key.contains("rate") { return "star.fill" }
        if key.contains("share") { return "square.and.arrow.up.fill" }
        if key.contains("kundali") || key.contains("astro") { return "sparkles" }
        return "chevron.right.circle.fill"
    }

    private func handleCTA(_ cta: UserSettingsCTA?) {
        guard let cta else { return }
        AppLog.info(.account, "settings tap · type=\(cta.type ?? "?") value=\(cta.value ?? "?")")
        let v = (cta.value ?? "").lowercased()
        if v.contains("logout") || v.contains("signout") { confirmLogout = true; return }
        if v.contains("delete") && v.contains("account") { confirmDelete = true; return }
        if v.contains("editprofile") || v.contains("profile") { showEditProfile = true; return }
    }

    private var destructiveActions: some View {
        VStack(spacing: 8) {
            Button { confirmLogout = true } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout").font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(14)
                .foregroundStyle(AppTheme.pinkAccent)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))

            Button { confirmDelete = true } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account").font(.subheadline.weight(.semibold))
                    if vm.isDeleting {
                        Spacer()
                        ProgressView().tint(.red)
                    } else {
                        Spacer()
                    }
                }
                .padding(14)
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
    }
}
