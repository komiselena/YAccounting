//
//  TransactionService.swift
//  YAccounting
//
//  Created by Mac on 08.06.2025.
//

import Foundation

final class TransactionService: ObservableObject, TransactionServiceProtocol, @unchecked Sendable {
    
    private let client: NetworkClient
    
    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }

    private var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: date)
            try container.encode(dateString)
        }
        return encoder
    }()

    

    private var mockTransactions: [Transaction] = [
        Transaction(
            id: 1,
            accountId: 1,
            categoryId: 1,
            amount: Decimal(50000.00),
            transactionDate: Date(),
            comment: "Зарплата за месяц",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 2,
            accountId: 1,
            categoryId: 1,
            amount: Decimal(1000.00),
            transactionDate: Date(),
            comment: "Доходы за месяц",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 3,
            accountId: 1,
            categoryId: 2,
            amount: Decimal(100.00),
            transactionDate: Date(),
            comment: "Аренда",
            createdAt: Date(),
            updatedAt: Date()
        ),
        Transaction(
            id: 4,
            accountId: 1,
            categoryId: 3,
            amount: Decimal(1500.00),
            transactionDate: Date(),
            comment: "Еда",
            createdAt: Date(),
            updatedAt: Date()
        ),

    ]

    var transactions: [TransactionResponse] = []
    
    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [TransactionResponse] {
        let endpoint = "api/v1/transactions/account/1/period?startDate=\(period.lowerBound.formatPeriod())&endDate=\(period.upperBound.formatPeriod())"
        return try await client.request(endpoint: endpoint)
    }

    func createTransaction(_ transaction: Transaction) async throws {
        let endpoint = "api/v1/transactions"
        let body = try encoder.encode(transaction)
        print("Request body: \(String(data: body, encoding: .utf8) ?? "")")
        let _: EmptyResponse = try await client.request(
            endpoint: endpoint,
            method: "POST",
            body: body
        )
        NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    }

    func editTransaction(_ transaction: Transaction) async throws {
        let endpoint = "api/v1/transactions/\(transaction.id)"
        
        do {
            let _: TransactionResponse = try await client.request(
                endpoint: "api/v1/transactions/\(transaction.id)",
                method: "GET"
            )
        } catch {
            throw NetworkError.customError(message: "Transaction not found")
        }
        
        let requestBody: [String: Any] = [
            "accountId": transaction.accountId,
            "categoryId": transaction.categoryId,
            "amount": NSDecimalNumber(decimal: transaction.amount).stringValue,
            "transactionDate": ISO8601DateFormatter().string(from: transaction.transactionDate),
            "comment": transaction.comment ?? ""
        ]
        
        
        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let _: EmptyResponse = try await client.request(
            endpoint: endpoint,
            method: "PUT",
            body: body
        )
        NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        let endpoint = "api/v1/transactions/\(transaction.id)"
        let _: EmptyResponse = try await client.request(
            endpoint: endpoint,
            method: "DELETE"
        )
        NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    }
}


extension Notification.Name {
    static let transactionsUpdated = Notification.Name("transactionsUpdated")
}

struct EmptyResponse: Decodable {}
