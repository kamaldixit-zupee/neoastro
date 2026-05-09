import SwiftUI
import UIKit

struct OTPView: View {
    @Environment(AuthViewModel.self) private var auth
    @Environment(AppConfigStore.self) private var config
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var auth = auth

        VStack(spacing: 0) {
            topBar
                .padding(.top, 16)

            Spacer(minLength: 0)

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Enter OTP")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.white)

                    Text("Sent to +91 \(auth.mobileNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                otpBoxes($auth.otp)
                resendRow
            }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button {
                    auth.verifyOTP(config: config)
                } label: {
                    HStack(spacing: 10) {
                        if auth.isLoading { ProgressView().tint(.white) }
                        Text(auth.isLoading ? "Verifying…" : "Verify & Continue")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(AppTheme.pinkAccent)
                .disabled(!auth.isOTPValid || auth.isLoading)
                .opacity((auth.isOTPValid && !auth.isLoading) ? 1.0 : 0.55)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
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

    private var topBar: some View {
        HStack {
            Button {
                auth.backToLogin()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func otpBoxes(_ otp: Binding<String>) -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { idx in
                    OTPBox(digit: digit(at: idx, in: otp.wrappedValue), isActive: idx == otp.wrappedValue.count)
                }
            }
        }
        .overlay(
            TextField("", text: otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.001)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: otp.wrappedValue) { _, newValue in
                    let trimmed = String(newValue.filter(\.isNumber).prefix(6))
                    if trimmed != newValue { otp.wrappedValue = trimmed }
                }
        )
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
    }

    private func digit(at index: Int, in otp: String) -> String {
        guard index < otp.count else { return "" }
        let i = otp.index(otp.startIndex, offsetBy: index)
        return String(otp[i])
    }

    private var resendRow: some View {
        Group {
            if auth.resendSecondsRemaining > 0 {
                Text("Resend OTP in \(auth.resendSecondsRemaining)s")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Button("Resend OTP") {
                    auth.sendOTP(resend: true)
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.pinkAccent)
            }
        }
    }
}

private struct OTPBox: View {
    let digit: String
    let isActive: Bool

    var body: some View {
        Text(digit)
            .font(.system(size: 26, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 48, height: 60)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? AppTheme.pinkAccent : .clear, lineWidth: 2)
            )
            .animation(.smooth(duration: 0.2), value: isActive)
    }
}

#Preview {
    ZStack {
        CosmicBackground()
        OTPView()
            .environment({
                let vm = AuthViewModel()
                vm.mobileNumber = "9876543210"
                vm.stage = .otp
                return vm
            }())
    }
}
