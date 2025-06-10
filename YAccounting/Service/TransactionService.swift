//
//  TransactionService.swift
//  YAccounting
//
//  Created by Mac on 08.06.2025.
//

import Foundation


final class TransactionService {
    private var mockTransactions: [Transaction] = [
        Transaction(accountId: 1, categoryId: 1, amount: 1000000, transactionDate: Date(), comment: "Salary"),
        Transaction(accountId: 2, categoryId: 2, amount: 5000, transactionDate: Date(), comment: "Rent")
        
    ]
    
    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        return mockTransactions.filter{ period.contains($0.transactionDate) }
    }
    
    func createTransactioin(_ transaction: Transaction) async throws {
        mockTransactions.append(transaction)
    }
    
    func editTransaction(_ transaction: Transaction) async throws {
        if let index = mockTransactions.firstIndex(where: { $0.accountId == transaction.accountId }) {
            mockTransactions[index] = transaction
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        mockTransactions.removeAll(where: { $0.accountId == transaction.accountId })
    }
    
}
