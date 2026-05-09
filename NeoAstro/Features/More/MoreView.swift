import SwiftUI
import SafariServices

struct MoreView: View {
    enum Destination: Hashable {
        case wallet
        case account
        case editProfile
        case about(items: [AboutItem])
    }

    struct AboutItem: Hashable {
        let displayText: String
        let value: String
    }

    private static let fallbackAboutItems: [AboutItem] = [
        .init(displayText: "About NeoAstro", value: "https://www.neoastro.com/about-us/?inapp=true"),
        .init(displayText: "Privacy Policy",  value: "https://www.neoastro.com/privacy-policy/"),
        .init(displayText: "Terms & Conditions", value: "https://www.neoastro.com/terms-and-conditions/")
    ]

    @Environment(AuthViewModel.self) private var auth
    @State private var vm = MoreViewModel()
    @State private var path: [Destination] = []
    @State private var confirmLogout = false
    @State private var confirmDelete = false
    @State private var safariURL: IdentifiedURL?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                CosmicBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        if vm.isLoading && vm.widgets.isEmpty {
                            ProgressView().tint(.white).controlSize(.large)
                                .padding(.top, 60)
                        } else if vm.widgets.isEmpty, let error = vm.widgetsError {
                            widgetsErrorBanner(error)
                                .padding(.top, 24)
                        }

                        if !standaloneWidgets.isEmpty {
                            ForEach(standaloneWidgets) { widget in
                                widgetSection(widget)
                            }
                        }

                        if !groupedItems.isEmpty {
                            groupedNavBox(groupedItems)
                        }

                        // Guaranteed About entry — falls back to defaults if the
                        // server didn't include an ABOUT widget.
                        if !hasAboutInGrouped {
                            aboutFallbackRow
                        }

                        destructiveActions

                        appVersionFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: Destination.self) { dest in
                switch dest {
                case .wallet:
                    WalletView()
                case .account:
                    AccountView()
                case .editProfile:
                    if let profile = vm.profile {
                        EditProfileView(profile: profile, onSaved: { Task { await vm.refresh() } })
                    } else {
                        profileUnavailableView
                    }
                case .about(let items):
                    aboutScreen(items: items)
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
            .sheet(item: $safariURL) { wrapped in
                SafariView(url: wrapped.url)
                    .ignoresSafeArea()
            }
            .task { await vm.load() }
        }
    }

    // MARK: - Widget grouping (zupee-style)

    private var standaloneWidgets: [UserSettingsWidget] {
        vm.widgets.filter { widget in
            let t = (widget.widgetType ?? "").lowercased()
            return t != "navigation_item_with_subtitle"
        }
    }

    private var groupedItems: [(widget: UserSettingsWidget, item: UserSettingsItem)] {
        vm.widgets
            .filter { ($0.widgetType ?? "").lowercased() == "navigation_item_with_subtitle" }
            .flatMap { widget in
                (widget.items ?? [])
                    .filter { $0.isVisible && ($0.title?.isEmpty == false) }
                    .map { (widget: widget, item: $0) }
            }
    }

    private var hasAboutInGrouped: Bool {
        groupedItems.contains { entry in
            (entry.item.cta?.value ?? "").uppercased() == "ABOUT"
        }
    }

    @ViewBuilder
    private func widgetSection(_ widget: UserSettingsWidget) -> some View {
        let type = (widget.widgetType ?? "").lowercased()
        switch type {
        case "profile_overview":
            profileOverview(widget)
        case "game_alerts_toggle", "language_toggle":
            toggleSection(widget)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func profileOverview(_ widget: UserSettingsWidget) -> some View {
        if let item = widget.items?.first(where: { $0.isVisible }) {
            Button { handleCTA(item.cta, item: item) } label: {
                HStack(spacing: 14) {
                    AvatarView(
                        name: item.username ?? "User",
                        imageURL: item.iconURL,
                        gradient: ["#7B2CBF", "#F72585"],
                        size: 64
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.username ?? "Profile")
                            .font(.headline)
                            .foregroundStyle(.white)
                        if let phone = item.description, !phone.isEmpty {
                            Text("+91 \(phone)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        if let action = item.subTitle, !action.isEmpty {
                            Text(action)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.pinkAccent)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    @ViewBuilder
    private func toggleSection(_ widget: UserSettingsWidget) -> some View {
        let visible = (widget.items ?? []).filter { $0.isVisible && ($0.title?.isEmpty == false) }
        if !visible.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(visible.enumerated()), id: \.element.stableID) { idx, item in
                    HStack(spacing: 14) {
                        Image(systemName: defaultIconName(for: item))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: .circle)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title ?? "")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            if let subtitle = item.subTitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        Spacer()

                        Toggle("", isOn: .constant(item.selected == item.options?.enable))
                            .labelsHidden()
                            .tint(AppTheme.pinkAccent)
                            .disabled(true)
                    }
                    .padding(14)

                    if idx < visible.count - 1 {
                        Divider().background(.white.opacity(0.08))
                    }
                }
            }
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
    }

    /// Renders all `navigation_item_with_subtitle` items into a single
    /// clubbed glass box with hairline dividers — matching zupee's
    /// account-screen "boxView".
    private func groupedNavBox(_ entries: [(widget: UserSettingsWidget, item: UserSettingsItem)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.item.stableID) { idx, entry in
                Button { handleCTA(entry.item.cta, item: entry.item) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: defaultIconName(for: entry.item))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: .circle)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.item.title ?? "")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            if let subtitle = entry.item.subTitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        if let tertiary = entry.item.tertiaryTitle, !tertiary.isEmpty {
                            Text(tertiary)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if idx < entries.count - 1 {
                    Divider().background(.white.opacity(0.08)).padding(.leading, 64)
                }
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private var aboutFallbackRow: some View {
        Button {
            path.append(.about(items: Self.fallbackAboutItems))
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text("About")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("App version, terms, privacy")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func defaultIconName(for item: UserSettingsItem) -> String {
        let cta = (item.cta?.value ?? "").lowercased()
        let title = (item.title ?? "").lowercased()
        let key = cta + "|" + title

        if key.contains("wallet") || key.contains("payment") { return "creditcard.fill" }
        if key.contains("alert") || key.contains("notification") { return "bell.fill" }
        if key.contains("language") { return "globe" }
        if key.contains("help") || key.contains("support") || key.contains("desk") { return "questionmark.circle.fill" }
        if key.contains("logout") || key.contains("signout") { return "rectangle.portrait.and.arrow.right" }
        if key.contains("delete") { return "trash.fill" }
        if key.contains("privacy") { return "lock.fill" }
        if key.contains("terms") { return "doc.text.fill" }
        if key.contains("rate") { return "star.fill" }
        if key.contains("share") || key.contains("refer") { return "square.and.arrow.up.fill" }
        if key.contains("about") { return "info.circle.fill" }
        if key.contains("kundali") || key.contains("astro") { return "sparkles" }
        if key.contains("profile") { return "person.fill" }
        return "chevron.right.circle.fill"
    }

    private func handleCTA(_ cta: UserSettingsCTA?, item: UserSettingsItem) {
        let v = (cta?.value ?? "").uppercased()
        AppLog.info(.account, "settings tap · type=\(cta?.type ?? "?") value=\(v)")

        switch v {
        case "WALLET":
            path.append(.wallet)
        case "PROFILE", "EDIT_PROFILE":
            path.append(.editProfile)
        case "HELPDESK", "HELP", "SUPPORT":
            if let link = cta?.link, let url = URL(string: link) { safariURL = IdentifiedURL(url: url) }
        case "ABOUT":
            // Trim the last three items the API includes (Responsible Gaming,
            // Fairplay, RNG Certificates) since they're zupee-specific links.
            let serverItems = (cta?.data?.items ?? []).compactMap { sub -> AboutItem? in
                guard let text = sub.displayText, let value = sub.value else { return nil }
                return AboutItem(displayText: text, value: value)
            }
            let trimmed = Array(serverItems.prefix(max(0, serverItems.count - 3)))
            path.append(.about(items: trimmed.isEmpty ? Self.fallbackAboutItems : trimmed))
        case "LOGOUT", "SIGNOUT":
            confirmLogout = true
        case "DELETE_ACCOUNT", "DELETEACCOUNT":
            confirmDelete = true
        case "WEBVIEW_LINK":
            if let value = cta?.value, let url = URL(string: value) {
                safariURL = IdentifiedURL(url: url)
            }
        default:
            if let link = cta?.link, let url = URL(string: link) {
                safariURL = IdentifiedURL(url: url)
            }
        }
    }

    // MARK: - About sub-screen

    private func aboutScreen(items: [AboutItem]) -> some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element) { idx, item in
                        Button {
                            if let url = URL(string: item.value) { safariURL = IdentifiedURL(url: url) }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: aboutIcon(for: item.displayText))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .glassEffect(.regular, in: .circle)

                                Text(item.displayText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if idx < items.count - 1 {
                            Divider().background(.white.opacity(0.08)).padding(.leading, 64)
                        }
                    }
                }
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
                .padding(.horizontal, 16)
                .padding(.top, 12)

                appVersionFooter
                    .padding(.top, 16)

                Spacer().frame(height: 100)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func aboutIcon(for label: String) -> String {
        let l = label.lowercased()
        if l.contains("privacy") { return "lock.fill" }
        if l.contains("terms") { return "doc.text.fill" }
        if l.contains("about") { return "info.circle.fill" }
        if l.contains("responsible") { return "checkmark.seal.fill" }
        if l.contains("fair") { return "scale.3d" }
        if l.contains("certif") || l.contains("rng") { return "rosette" }
        return "doc.text.fill"
    }

    private var appVersionFooter: some View {
        VStack(spacing: 4) {
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                let build = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
                Text("Version \(version) (\(build))")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(APIEnvironment.current.name.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var profileUnavailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text("Profile not available right now")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Button("Retry") { Task { await vm.refresh() } }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CosmicBackground())
    }

    // MARK: - Errors + destructive actions

    private func widgetsErrorBanner(_ error: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            Text("Couldn't load settings")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(error)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await vm.refresh() } }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private var destructiveActions: some View {
        VStack(spacing: 0) {
            Button { confirmLogout = true } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout").font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .padding(14)
                .foregroundStyle(AppTheme.pinkAccent)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().background(.white.opacity(0.08)).padding(.leading, 50)

            Button { confirmDelete = true } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account").font(.subheadline.weight(.semibold))
                    Spacer()
                    if vm.isDeleting { ProgressView().tint(.red) }
                }
                .padding(14)
                .foregroundStyle(.red)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}

// MARK: - Helpers

private struct IdentifiedURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_: SFSafariViewController, context: Context) {}
}
