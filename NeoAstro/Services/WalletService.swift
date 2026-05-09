import Foundation

enum WalletService {
    static func screenData() async throws -> WalletScreenData {
        try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/getWalletScreenData",
            method: .GET
        ), as: WalletScreenData.self)
    }

    static func transactionHistory(skip: Int = 0, limit: Int = 20) async throws -> [WalletTransactionAPI] {
        struct Wrapper: Decodable { let transactions: [WalletTransactionAPI]? }
        let result = try await APIClient.shared.send(.init(
            path: "/v1.0/wallet/transactionHistory/passbook",
            method: .GET,
            query: ["skip": "\(skip)", "limit": "\(limit)"]
        ), as: Wrapper.self)
        return result.transactions ?? []
    }

    static func createCheckoutOrder(amount: Int, instrumentType: String = "UPI") async throws -> CheckoutOrderResponse {
        try await APIClient.shared.send(.init(
            path: "/v1.0/payment/v2/checkoutOrder/create",
            method: .POST,
            body: CheckoutOrderBody(amount: amount, instrumentType: instrumentType)
        ), as: CheckoutOrderResponse.self)
    }
}
