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

    var transactions: [TransactionResponse] = []
    
    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [TransactionResponse] {
        do{
            transactions = try await NetworkClient.shared.fetchDecodeData(enpointValue: "api/v1/transactions/account/1/period?startDate=\(period.lowerBound.formatPeriod())&endDate=\(period.upperBound.formatPeriod())", dataType: TransactionResponse.self)
            return transactions
        }catch{
            print (error)
            throw URLError(.unknown)
        }
    }
    
//    func fetchTransaction(id: Int) async throws {
//        do{
//            try await NetworkClient.shared.requestTransactionOperation(id, httpMethod: "GET")
//        }catch{
//            print (error)
//            throw URLError(.unknown)
//        }
//    }

    
    func createTransaction(_ transaction: Transaction) async throws {
        do{
            try await NetworkClient.shared.requestTransactionOperation(transaction, httpMethod: "POST", isDelete: false, isCreate: true)
        }catch{
            print (error)
            throw URLError(.unknown)
        }
    }
    
    func editTransaction(_ transaction: Transaction) async throws {
            do{
                try await NetworkClient.shared.requestTransactionOperation(transaction, httpMethod: "PUT")
            }catch{
                print (error)
                throw URLError(.unknown)
            }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        do{
            try await NetworkClient.shared.requestTransactionOperation(transaction, httpMethod: "DELETE", isDelete: true)
        }catch{
            print (error)
            throw URLError(.unknown)
        }

    }
    
}


