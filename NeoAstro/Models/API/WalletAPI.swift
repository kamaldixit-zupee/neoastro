import Foundation

struct WalletScreenData: Decodable {
    let walletBalance: Double?
    let userDetail: UserDetails?
    let recentTransactions: [WalletTransactionAPI]?
    let transactions: [WalletTransactionAPI]?
}

struct WalletTransactionAPI: Decodable, Identifiable, Hashable {
    let _id: String?
    let type: String?
    let amount: Double?
    let description: String?
    let timestamp: Double?
    let balanceAfter: Double?
    let title: String?
    let subtitle: String?

    var id: String { _id ?? UUID().uuidString }

    var date: Date {
        guard let ts = timestamp else { return .now }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }

    var isCredit: Bool {
        if let type = type?.uppercased() { return type == "CREDIT" }
        return (amount ?? 0) > 0
    }

    var displayAmount: Int { Int(abs(amount ?? 0)) }
    var displayTitle: String { title ?? description ?? (isCredit ? "Wallet credit" : "Consultation") }
    var displaySubtitle: String { subtitle ?? "" }
}

struct CheckoutOrderResponse: Decodable {
    let orderId: String?
    let clientAuthToken: String?
    let success: Bool?
    let amount: Double?
}

struct CheckoutOrderBody: Encodable {
    let amount: Int
    let instrumentType: String
}
