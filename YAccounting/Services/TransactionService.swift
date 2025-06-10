//
//  TransactionService.swift
//  YAccounting
//
//  Created by Mac on 08.06.2025.
//

import Foundation


final class TransactionService {
    private var mockTransactions: [Transaction] = [
        Transaction(
            id: 1,
            accountId: 1,
            categoryId: 1,
            amount: Decimal(500.00),
            transactionDate: Date(),
            comment: "Зарплата за месяц",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]

    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        return mockTransactions.filter{ period.contains($0.transactionDate) }
    }
    
    func createTransactioin(_ transaction: Transaction) async throws {
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
