import SwiftUI

/// First-launch language picker. Persists the chosen language code into
/// `TokenStore` (which `DeviceInfo.language` reads on every wire request) and
/// asks the `AuthViewModel` to advance to the next stage.
struct LanguageSelectionView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(AppConfigStore.self) private var config

    @State private var selectedCode: String?

    private var languages: [PreSignupConfig.SupportedLanguage] {
        config.supportedLanguages
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 56)
                .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(languages) { lang in
                        LanguageTile(
                            language: lang,
                            isSelected: selectedCode == lang.code,
                            onTap: { selectedCode = lang.code }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)

            continueButton
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Choose your language")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("You can change this anytime in More")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var continueButton: some View {
        Button {
            guard let code = selectedCode else { return }
            TokenStore.shared.language = code
            AppLog.info(.config, "language saved code=\(code)")
            auth.languageSelected()
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(AppTheme.pinkAccent)
        .disabled(selectedCode == nil)
        .opacity(selectedCode == nil ? 0.55 : 1.0)
    }
}

private struct LanguageTile: View {
    let language: PreSignupConfig.SupportedLanguage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(language.displayPrimary)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let secondary = language.displaySecondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text(language.code.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCorner)
                .stroke(isSelected ? AppTheme.pinkAccent : .white.opacity(0.10),
                        lineWidth: isSelected ? 2 : 1)
        )
        .animation(.smooth(duration: 0.2), value: isSelected)
    }
}
