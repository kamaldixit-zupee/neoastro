import SwiftUI
import Observation

@Observable
@MainActor
final class WalletViewModel {
    var balance: Int = 0
    var transactions: [WalletTransactionAPI] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var isCheckoutLoading: Bool = false
    var pendingCheckoutAmount: Int = 0
    var checkoutSession: CheckoutOrderResponse?

    func load() async {
        guard balance == 0 && transactions.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        AppLog.info(.wallet, "VM · refresh start")
        isLoading = true
        errorMessage = nil
        do {
            let data = try await WalletService.screenData()
            balance = Int(data.walletBalance ?? 0)
            let combined = (data.recentTransactions ?? []) + (data.transactions ?? [])
            transactions = combined.uniqued(by: { $0.id })
            AppLog.info(.wallet, "VM · refresh success balance=\(balance) tx=\(transactions.count)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "VM · refresh failed", error: error)
        }
        isLoading = false
    }

    func startCheckout(amount: Int) async -> CheckoutOrderResponse? {
        AppLog.info(.wallet, "VM · startCheckout amount=\(amount)")
        isCheckoutLoading = true
        errorMessage = nil
        defer { isCheckoutLoading = false }
        do {
            let session = try await WalletService.createCheckoutOrder(amount: amount)
            checkoutSession = session
            pendingCheckoutAmount = amount
            AppLog.info(.wallet, "VM · startCheckout success orderId=\(session.orderId ?? "?")")
            return session
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "VM · startCheckout failed", error: error)
            return nil
        }
    }

    func confirmCheckoutSuccess() async {
        await refresh()
    }
}

private extension Array {
    func uniqued<H: Hashable>(by key: (Element) -> H) -> [Element] {
        var seen = Set<H>()
        return filter { seen.insert(key($0)).inserted }
    }
}
