//
//  TransactionService.swift
//  YAccounting
//
//  Created by Mac on 08.06.2025.
//

import Foundation

final actor TransactionService: ObservableObject, TransactionServiceProtocol {
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

    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        return mockTransactions.filter{ period.contains($0.transactionDate) }
    }
    
    func createTransaction(_ transaction: Transaction) async throws {
        mockTransactions.append(transaction)
    }
    
    func editTransaction(_ transaction: Transaction) async throws {
        if let index = mockTransactions.firstIndex(where: { $0.id == transaction.id }) {
            mockTransactions[index] = transaction
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        mockTransactions.removeAll(where: { $0.id == transaction.id })
    }
    
}

