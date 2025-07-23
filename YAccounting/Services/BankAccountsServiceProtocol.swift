//
//  BankAccountsServiceProtocol.swift
//  YAccounting
//
//  Created by Mac on 28.06.2025.
//

import Foundation

protocol BankAccountsServiceProtocol {
    
    func fetchBankAccount(forceReload: Bool) async throws -> BankAccount
    func changeBankAccount(_ bankAccount: BankAccount) async throws
    func recalculateBalance(transactions: [Transaction], categories: [Category]) async throws
    func updateBalanceForTransaction(_ transaction: Transaction, category: Category, isAdding: Bool) async throws
    
    
}
