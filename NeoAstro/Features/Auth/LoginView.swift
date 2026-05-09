import SwiftUI
import UIKit

struct LoginView: View {
    @Environment(AuthViewModel.self) private var auth
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var auth = auth

        VStack(spacing: 0) {
            header
                .padding(.top, 60)

            Spacer(minLength: 0)

            mobileField($auth.mobileNumber)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)

            footer
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
                    .font(.body.weight(.semibold))
            }
        }
        .onAppear { focused = true }
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 110, height: 110)
                    .blur(radius: 22)
                    .opacity(0.55)

                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .padding(16)
                    .glassEffect(.regular, in: .circle)
            }

            Text("NeoAstro")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("Cosmic guidance, on demand")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func mobileField(_ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mobile number")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            HStack(spacing: 10) {
                Text("+91")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: .capsule)

                TextField("", text: binding, prompt: Text("10-digit number").foregroundColor(.white.opacity(0.45)))
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .focused($focused)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .tint(AppTheme.pinkAccent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .glassEffect(.regular, in: .capsule)
                    .onChange(of: binding.wrappedValue) { _, newValue in
                        let trimmed = String(newValue.filter(\.isNumber).prefix(10))
                        if trimmed != newValue { binding.wrappedValue = trimmed }
                    }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
            }

            Button {
                auth.sendOTP()
            } label: {
                HStack(spacing: 10) {
                    if auth.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(auth.isLoading ? "Sending OTP…" : "Send OTP")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)
            .disabled(!auth.isMobileValid || auth.isLoading)
            .opacity((auth.isMobileValid && !auth.isLoading) ? 1.0 : 0.55)

            termsText
        }
    }

    private var termsText: some View {
        let base = "By continuing you agree to our Terms of Service and Privacy Policy"
        var attributed = AttributedString(base)
        attributed.foregroundColor = .white.opacity(0.6)
        attributed.font = .footnote

        if let r = attributed.range(of: "Terms of Service") {
            attributed[r].foregroundColor = .white
            attributed[r].underlineStyle = .single
        }
        if let r = attributed.range(of: "Privacy Policy") {
            attributed[r].foregroundColor = .white
            attributed[r].underlineStyle = .single
        }
        return Text(attributed).multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        CosmicBackground()
        LoginView()
            .environment(AuthViewModel())
    }
}
