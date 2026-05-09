import SwiftUI

struct TransactionDetailView: View {
    let tx: WalletTransactionAPI

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    amountCard
                    detailsCard
                    if tx.invoiceNumber != nil {
                        invoiceCard
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Amount hero

    private var amountCard: some View {
        VStack(spacing: 14) {
            Image(systemName: tx.isCredit ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(tx.isCredit ? .green : AppTheme.pinkAccent)
                .padding(20)
                .glassEffect(.regular, in: .circle)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(tx.isCredit ? "+" : "−")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("₹")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(tx.displayAmount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(tx.isCredit ? .green : .white)
            }

            Text(tx.displayTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if let subtitle = tx.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }

    // MARK: - Details list

    private var detailsCard: some View {
        VStack(spacing: 0) {
            row("Date", value: Self.dateFormatter.string(from: tx.date))
            divider
            if let category = tx.category, !category.isEmpty {
                row("Category", value: category.replacingOccurrences(of: "_", with: " ").capitalized)
                divider
            }
            if let mode = tx.paymentMode, !mode.isEmpty {
                row("Payment mode", value: mode)
                divider
            }
            if let astroName = tx.astrologerName, !astroName.isEmpty {
                row("Astrologer", value: astroName)
                divider
            }
            if let balance = tx.balanceAfter {
                row("Balance after", value: "₹\(Int(balance))")
                divider
            }
            row("Type", value: tx.isCredit ? "Credit" : "Debit", lastRow: true)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }

    private func row(_ label: String, value: String, lastRow: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 16)
    }

    // MARK: - Invoice

    private var invoiceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.goldGradient)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invoice")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if let invoiceNumber = tx.invoiceNumber {
                        Text(invoiceNumber)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                Spacer()
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.pinkAccent)
            }
            .padding(14)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }
}
