//
//  TransactionProtocol.swift
//  YAccounting
//
//  Created by Mac on 16.07.2025.
//

import Foundation

protocol TransactionProtocol {
    
    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [TransactionResponse]
    func createTransaction(id: Int) async throws
    func editTransaction(id: Int) async throws
    func deleteTransaction(id: Int) async throws
    
}
