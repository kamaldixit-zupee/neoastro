import Foundation

enum WalletService {

    // MARK: - Screen data + passbook

    static func screenData() async throws -> WalletScreenData {
        try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/getWalletScreenData",
            method: .GET
        ), as: WalletScreenData.self)
    }

    static func transactionHistory(skip: Int = 0, limit: Int = 20, filter: String? = nil) async throws -> [WalletTransactionAPI] {
        struct Wrapper: Decodable { let transactions: [WalletTransactionAPI]? }
        var query: [String: String] = ["skip": "\(skip)", "limit": "\(limit)"]
        if let filter, !filter.isEmpty { query["filter"] = filter }
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/transactionHistory/passbook",
            method: .GET,
            query: query
        ), as: Wrapper.self)
        return result.transactions ?? []
    }

    static func transactionFilters() async throws -> TransactionFilterResponse {
        try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/transactionHistory/filters",
            method: .GET
        ), as: TransactionFilterResponse.self)
    }

    // MARK: - Checkout (deposit)

    static func createCheckoutOrder(amount: Int, instrumentType: String = "UPI") async throws -> CheckoutOrderResponse {
        try await APIClient.shared.send(.init(
            path: "/v1.0/payment/v2/checkoutOrder/create",
            method: .POST,
            body: CheckoutOrderBody(amount: amount, instrumentType: instrumentType)
        ), as: CheckoutOrderResponse.self)
    }

    // MARK: - Cashback / coins

    static func cashbackList() async throws -> CashbackResponse {
        try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/fetchActiveCashbackCoins",
            method: .GET
        ), as: CashbackResponse.self)
    }

    static func convertActualCoins(amount: Int) async throws {
        try await APIClient.shared.sendVoid(.init(
            path: "/v1.0/payment/convertActualCoins",
            method: .POST,
            body: ConvertCoinsBody(amount: amount)
        ))
    }

    // MARK: - TDS

    static func tdsCertificates() async throws -> [TDSCertificate] {
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/tds/getTDSCertificates",
            method: .GET
        ), as: TDSCertificateList.self)
        return result.certificates ?? []
    }

    static func userTDSInfo() async throws -> UserTDSInfo {
        try await APIClient.shared.send(.init(
            path: "/v1.0/tds/getUserTdsInfo",
            method: .GET
        ), as: UserTDSInfo.self)
    }

    static func tdsCertOfQuarter(quarter: String, financialYear: String) async throws -> TDSCertificate {
        try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/tds/getTdsCertificationOfQuarter",
            method: .GET,
            query: ["quarter": quarter, "financialYear": financialYear]
        ), as: TDSCertificate.self)
    }

    static func tdsTransactionsOfQuarter(quarter: String, financialYear: String) async throws -> TDSTransactionsResponse {
        try await APIClient.shared.send(.init(
            path: "/v1.0/tds/getTdsTransactionOfQuarter",
            method: .POST,
            body: TDSTransactionsBody(quarter: quarter, financialYear: financialYear)
        ), as: TDSTransactionsResponse.self)
    }

    // MARK: - Invoices

    static func invoices() async throws -> [Invoice] {
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/getInvoices",
            method: .GET
        ), as: InvoiceList.self)
        return result.invoices ?? []
    }
}
