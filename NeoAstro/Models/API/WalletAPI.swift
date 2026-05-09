import Foundation

// MARK: - Wallet screen / passbook

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
    let category: String?         // e.g. "DEPOSIT" / "CHAT" / "TDS"
    let astrologerName: String?
    let astrologerImage: String?
    let invoiceNumber: String?
    let paymentMode: String?

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

// MARK: - Checkout

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

// MARK: - Transaction filters

struct TransactionFilterOption: Decodable, Identifiable, Hashable {
    let _id: String?
    let label: String?
    let value: String?

    var id: String { _id ?? value ?? label ?? UUID().uuidString }
}

struct TransactionFilterResponse: Decodable {
    let filters: [TransactionFilterOption]?
    let dateRanges: [TransactionFilterOption]?
}

// MARK: - Cashback / coins

struct CashbackResponse: Decodable {
    let activeCoins: Double?
    let totalCoins: Double?
    let cashbacks: [CashbackItem]?
}

struct CashbackItem: Decodable, Identifiable, Hashable {
    let _id: String?
    let title: String?
    let subtitle: String?
    let amount: Double?
    let expiryTimestamp: Double?
    let iconUrl: String?
    let isClaimable: Bool?

    var id: String { _id ?? UUID().uuidString }
    var displayAmount: Int { Int(amount ?? 0) }
    var expiryDate: Date? {
        guard let ts = expiryTimestamp else { return nil }
        return Date(timeIntervalSince1970: ts > 1_000_000_000_000 ? ts / 1000 : ts)
    }
}

struct ConvertCoinsBody: Encodable {
    let amount: Int
}

// MARK: - TDS

struct TDSCertificateList: Decodable {
    let certificates: [TDSCertificate]?
}

struct TDSCertificate: Decodable, Identifiable, Hashable {
    let _id: String?
    let quarter: String?
    let financialYear: String?
    let amount: Double?
    let downloadUrl: String?
    let issuedDate: String?

    var id: String { _id ?? "\(quarter ?? "")_\(financialYear ?? "")" }
    var displayAmount: Int { Int(amount ?? 0) }
    var displayLabel: String {
        let q = quarter ?? "?"
        let y = financialYear ?? "?"
        return "\(q) · \(y)"
    }
}

struct UserTDSInfo: Decodable {
    let totalTdsDeducted: Double?
    let panNumber: String?
    let financialYear: String?
    let panMasked: String?
}

struct TDSCertificateRequestBody: Encodable {
    let quarter: String
    let financialYear: String
}

struct TDSTransactionsBody: Encodable {
    let quarter: String
    let financialYear: String
}

struct TDSTransactionsResponse: Decodable {
    let transactions: [WalletTransactionAPI]?
    let totalAmount: Double?
}

// MARK: - Invoices

struct InvoiceList: Decodable {
    let invoices: [Invoice]?
}

struct Invoice: Decodable, Identifiable, Hashable {
    let _id: String?
    let invoiceNumber: String?
    let issuedDate: String?
    let amount: Double?
    let downloadUrl: String?
    let title: String?
    let astrologerName: String?

    var id: String { _id ?? invoiceNumber ?? UUID().uuidString }
    var displayAmount: Int { Int(amount ?? 0) }
}
