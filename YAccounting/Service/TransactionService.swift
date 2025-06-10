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
            account: Transaction.Account(
                id: 1,
                name: "Основной счёт",
                balance: Decimal(1000.00),
                currency: "RUB"
            ),
            category: Category(
                id: 1,
                name: "Зарплата",
                emoji: "💰",
                isIncome: true
            ),
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
