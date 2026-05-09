import SwiftUI

@Observable
@MainActor
final class CashbackViewModel {
    var activeCoins: Int = 0
    var totalCoins: Int = 0
    var cashbacks: [CashbackItem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var convertingAmount: Int?
    var convertError: String?

    func load() async {
        guard cashbacks.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        AppLog.info(.wallet, "VM · cashback refresh start")
        do {
            let result = try await WalletService.cashbackList()
            activeCoins = Int(result.activeCoins ?? 0)
            totalCoins = Int(result.totalCoins ?? 0)
            cashbacks = result.cashbacks ?? []
            AppLog.info(.wallet, "VM · cashback refresh ok active=\(activeCoins) items=\(cashbacks.count)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "cashback list failed", error: error)
        }
        isLoading = false
    }

    func convert(amount: Int) async {
        guard amount > 0 else { return }
        convertingAmount = amount
        convertError = nil
        AppLog.info(.wallet, "VM · convert coins amount=\(amount)")
        do {
            try await WalletService.convertActualCoins(amount: amount)
            await refresh()
        } catch {
            convertError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "convert coins failed", error: error)
        }
        convertingAmount = nil
    }
}

struct CashbackView: View {
    @State private var vm = CashbackViewModel()

    private static let expiryFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    coinsCard
                    cashbackSection
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .refreshable { await vm.refresh() }
        }
        .navigationTitle("Cashback")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await vm.load() }
    }

    private var coinsCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.goldGradient)
                .padding(14)
                .glassEffect(.regular, in: .circle)

            VStack(spacing: 4) {
                Text("Active coins")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("₹")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(vm.activeCoins)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.goldGradient)
                        .contentTransition(.numericText())
                        .animation(.smooth, value: vm.activeCoins)
                }
                if vm.totalCoins > 0 {
                    Text("Total earned: ₹\(vm.totalCoins)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            if vm.activeCoins > 0 {
                Button {
                    Task { await vm.convert(amount: vm.activeCoins) }
                } label: {
                    HStack(spacing: 8) {
                        if vm.convertingAmount != nil {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.left.arrow.right")
                        }
                        Text(vm.convertingAmount != nil ? "Converting…" : "Convert to wallet")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .tint(AppTheme.pinkAccent)
                .disabled(vm.convertingAmount != nil)
            }

            if let err = vm.convertError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }

    @ViewBuilder
    private var cashbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cashback offers")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if vm.isLoading && !vm.cashbacks.isEmpty {
                    ProgressView().tint(.white)
                }
            }
            .padding(.horizontal, 4)

            if vm.isLoading && vm.cashbacks.isEmpty {
                ProgressView().tint(.white).controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if vm.cashbacks.isEmpty {
                Text(vm.errorMessage ?? "No active cashback offers right now.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(vm.errorMessage == nil ? 0.65 : 0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.cashbacks) { item in
                        offerRow(item)
                    }
                }
            }
        }
    }

    private func offerRow(_ item: CashbackItem) -> some View {
        HStack(spacing: 12) {
            iconView(for: item)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title ?? "Cashback")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                }
                if let expiry = item.expiryDate {
                    Text("Expires \(Self.expiryFormatter.string(from: expiry))")
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.85))
                }
            }

            Spacer()

            Text("₹\(item.displayAmount)")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.goldGradient)
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func iconView(for item: CashbackItem) -> some View {
        if let urlString = item.iconUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().padding(6)
                default:
                    Image(systemName: "gift.fill").foregroundStyle(AppTheme.goldGradient)
                }
            }
            .frame(width: 40, height: 40)
            .glassEffect(.regular, in: .circle)
        } else {
            Image(systemName: "gift.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)
        }
    }
}
