import SwiftUI

struct WalletView: View {
    @State private var vm = WalletViewModel()
    @State private var amountText: String = ""
    @State private var showJuspay = false
    @State private var selectedTransaction: WalletTransactionAPI?
    @State private var showTDS: Bool = false
    @State private var showCashback: Bool = false
    @State private var showFilterSheet = false
    @State private var activeFilter: String?
    @Environment(DeepLinkRouter.self) private var deepLinks
    @FocusState private var amountFocused: Bool

    private let quickAmounts = [100, 500, 1000, 2000]

    private var amountInt: Int { Int(amountText.filter(\.isNumber)) ?? 0 }
    private var canAdd: Bool { amountInt >= 10 }

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    balanceCard
                    quickLinksRow
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
        .navigationDestination(item: $selectedTransaction) { tx in
            TransactionDetailView(tx: tx)
        }
        .navigationDestination(isPresented: $showTDS) { TDSView() }
        .navigationDestination(isPresented: $showCashback) { CashbackView() }
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
            .presentationDragIndicator(.visible)
        }
        .task { await vm.load() }
        .onChange(of: deepLinks.intent) { _, newValue in
            handleDeepLink(newValue)
        }
        .task { handleDeepLink(deepLinks.intent) }
    }

    private func handleDeepLink(_ intent: DeepLinkRouter.Intent?) {
        guard let intent else { return }
        switch intent {
        case .deposit(let amount):
            amountText = "\(amount)"
            amountFocused = true
            _ = deepLinks.consume()
        case .wallet:
            // Already on Wallet — just clear the intent.
            _ = deepLinks.consume()
        default:
            break
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
        .background(AppTheme.balanceCardGradient, in: .rect(cornerRadius: AppTheme.cardCorner))
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
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

    private var quickLinksRow: some View {
        HStack(spacing: 10) {
            quickLink(icon: "gift.fill", title: "Cashback") { showCashback = true }
            quickLink(icon: "doc.text.fill", title: "TDS") { showTDS = true }
        }
    }

    private func quickLink(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppTheme.goldGradient)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .circle)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(12)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
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
                        Button {
                            selectedTransaction = tx
                        } label: {
                            TransactionRow(tx: tx)
                        }
                        .buttonStyle(.plain)
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

#Preview {
    NavigationStack {
        WalletView()
    }
    .previewEnvironment()
}
