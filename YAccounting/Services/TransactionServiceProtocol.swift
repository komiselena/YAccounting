//
//  TransactionServiceProtocol.swift
//  YAccounting
//
//  Created by Mac on 28.06.2025.
//


import Foundation

protocol TransactionServiceProtocol {
    
    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction]
    func createTransaction(_ transaction: Transaction) async throws
    func editTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(_ transaction: Transaction) async throws
    
}
