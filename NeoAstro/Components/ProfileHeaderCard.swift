import SwiftUI

/// The avatar + name + phone + pills + Edit-Profile card. Shared by the
/// Account screen and the top of the More tab so both render the same hero
/// block, sourced from the keychain cache.
struct ProfileHeaderCard: View {
    let profile: UserDetails?
    var onEditProfile: () -> Void

    private var displayName: String {
        if let name = profile?.name, !name.isEmpty { return name }
        return "NeoAstro User"
    }

    private var displayPhone: String {
        let stored = profile?.phone ?? TokenStore.shared.mobileNumber ?? ""
        return stored.isEmpty ? "" : "+91 \(stored)"
    }

    private var zodiacName: String? {
        profile?.zodiacName ?? TokenStore.shared.zodiacName
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 110, height: 110)
                    .blur(radius: 22)
                    .opacity(0.4)

                AvatarView(
                    name: displayName,
                    imageURL: profile?.profilePictureUrl.flatMap(URL.init(string:)),
                    gradient: AppTheme.primaryAvatarPalette,
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
                if let zodiac = zodiacName {
                    pill(icon: "sparkles", text: zodiac)
                }
                pill(icon: "star.fill", text: "Member")
            }

            Button(action: onEditProfile) {
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
}

#if DEBUG
#Preview {
    ZStack {
        CosmicBackground()
        ProfileHeaderCard(profile: nil, onEditProfile: {})
            .padding()
    }
}
#endif
