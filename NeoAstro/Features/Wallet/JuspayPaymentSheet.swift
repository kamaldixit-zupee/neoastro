import SwiftUI

struct JuspayPaymentSheet: View {
    let amount: Int
    let onComplete: (Bool) -> Void

    enum Phase { case selectMethod, processing, success }

    @State private var phase: Phase = .selectMethod
    @State private var selectedMethod: PaymentMethod = .upi

    enum PaymentMethod: String, CaseIterable, Identifiable {
        case upi = "UPI"
        case card = "Credit / Debit Card"
        case netbanking = "Netbanking"
        case wallet = "Wallets"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .upi: "indianrupeesign.circle.fill"
            case .card: "creditcard.fill"
            case .netbanking: "building.columns.fill"
            case .wallet: "wallet.pass.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            header

            Group {
                switch phase {
                case .selectMethod: selectMethodView
                case .processing: processingView
                case .success: successView
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.smooth, value: phase)

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                Text("Juspay")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text("Paying ₹\(amount) to NeoAstro")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var selectMethodView: some View {
        VStack(spacing: 8) {
            ForEach(PaymentMethod.allCases) { method in
                Button {
                    selectedMethod = method
                    pay()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: method.icon)
                            .font(.title3)
                            .foregroundStyle(AppTheme.goldGradient)
                            .frame(width: 36, height: 36)
                            .glassEffect(.regular, in: .circle)

                        Text(method.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(AppTheme.cardPadding)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
            }

            Button("Cancel") { onComplete(false) }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 6)
        }
    }

    private var processingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
                .padding(.vertical, 16)
            Text("Processing payment…")
                .font(.subheadline)
                .foregroundStyle(.white)
            Text("via \(selectedMethod.rawValue)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 28)
    }

    private var successView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .nonRepeating)

            Text("Payment Successful")
                .font(.headline)
                .foregroundStyle(.white)

            Text("₹\(amount) added to your wallet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.vertical, 22)
    }

    private func pay() {
        phase = .processing
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            phase = .success
            try? await Task.sleep(for: .seconds(1.0))
            onComplete(true)
        }
    }
}

#Preview {
    JuspayPaymentSheet(amount: 500) { _ in }
}
