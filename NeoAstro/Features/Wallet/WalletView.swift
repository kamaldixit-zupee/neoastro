import SwiftUI

struct WalletView: View {
    @State private var vm = WalletViewModel()
    @State private var amountText: String = ""
    @State private var showJuspay = false
    @FocusState private var amountFocused: Bool

    private let quickAmounts = [100, 500, 1000, 2000]

    private var amountInt: Int { Int(amountText.filter(\.isNumber)) ?? 0 }
    private var canAdd: Bool { amountInt >= 10 }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        balanceCard
                        addBalanceCard
                        transactionsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Wallet")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { amountFocused = false }
                        .font(.body.weight(.semibold))
                }
            }
            .sheet(isPresented: $showJuspay) {
                JuspayPaymentSheet(amount: amountInt) { success in
                    showJuspay = false
                    if success {
                        amountText = ""
                        amountFocused = false
                        Task { await vm.confirmCheckoutSuccess() }
                    }
                }
                .presentationDetents([.medium])
                .presentationBackground(.clear)
            }
            .task { await vm.load() }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wallet Balance")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                if vm.isLoading && vm.balance == 0 {
                    ProgressView().tint(.white).padding(.leading, 8)
                } else {
                    Text("\(vm.balance)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.goldGradient)
                        .contentTransition(.numericText())
                        .animation(.smooth, value: vm.balance)
                }
            }

            Text("Available for consultations")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#7209B7").opacity(0.55), Color(hex: "#F72585").opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: 24)
        )
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private var addBalanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Balance")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                Text("₹")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)

                TextField("", text: $amountText, prompt: Text("Enter amount").foregroundColor(.white.opacity(0.45)))
                    .keyboardType(.numberPad)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .tint(AppTheme.pinkAccent)
                    .focused($amountFocused)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)
            }

            HStack(spacing: 8) {
                ForEach(quickAmounts, id: \.self) { amt in
                    Button { amountText = "\(amt)" } label: {
                        Text("₹\(amt)")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                    .tint(.white)
                }
            }

            Button {
                amountFocused = false
                Task {
                    if await vm.startCheckout(amount: amountInt) != nil {
                        showJuspay = true
                    } else {
                        showJuspay = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if vm.isCheckoutLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(canAdd ? "Add ₹\(amountInt) via Juspay" : "Add Balance")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)
            .disabled(!canAdd || vm.isCheckoutLoading)
            .opacity((canAdd && !vm.isCheckoutLoading) ? 1.0 : 0.55)
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if vm.isLoading && !vm.transactions.isEmpty {
                    ProgressView().tint(.white)
                }
            }
            .padding(.horizontal, 4)

            if vm.transactions.isEmpty && !vm.isLoading {
                Text("No transactions yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.transactions) { tx in
                        TransactionRow(tx: tx)
                    }
                }
            }
        }
    }
}

private struct TransactionRow: View {
    let tx: WalletTransactionAPI

    private static let dateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tx.isCredit ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                .font(.title3)
                .foregroundStyle(tx.isCredit ? .green : AppTheme.pinkAccent)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !tx.displaySubtitle.isEmpty {
                    Text(tx.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(tx.isCredit ? "+" : "−")₹\(tx.displayAmount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tx.isCredit ? .green : .white)
                Text(Self.dateFormatter.localizedString(for: tx.date, relativeTo: .now))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
