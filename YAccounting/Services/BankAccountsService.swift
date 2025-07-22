//
//  BankAccountsService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation
import SwiftData

@MainActor
final class BankAccountsService: BankAccountsServiceProtocol {
    
    
    private let client: NetworkClient
    private let storage = BankAccountSwiftDataStorage()
    
    init(
        client: NetworkClient = NetworkClient(),
    ) {
        self.client = client
    }
    
    private var mockBankAccount: BankAccount = BankAccount(
        id: 1,
        userId: 1,
        name: "main",
        balance: "100000.9",
        currency: "RUB",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    var bankAccount: BankAccount?
    
    func fetchBankAccount() async throws -> BankAccount {
        do {
            let bankAccounts: [BankAccount] = try await client.request(endpoint: "api/v1/accounts", method: "GET")
            let selectedAccount = bankAccounts.first ?? mockBankAccount
            bankAccount = selectedAccount
            
            try storage.save(bankAccount: selectedAccount)
            
            return selectedAccount
        } catch {
            print("Ошибка запроса: \(error)")
            
            if let local = try? storage.fetchBankAccount() {
                print("Загружаем из SwiftData: \(local)")
                return local
            } else {
                return mockBankAccount
            }
        }
    }
    
    func changeBankAccount(_ bankAccount: BankAccount) async throws {
        var updatedAccount = bankAccount
        updatedAccount.updatedAt = Date()
        
        mockBankAccount = updatedAccount
        
        try storage.save(bankAccount: updatedAccount)
        
    }
    func updateBankAccount(name: String, balance: Decimal, currency: String) async throws {
        var account = try await fetchBankAccount()
        account.name = name
        // Используем правильное преобразование Decimal в String
        account.balance = NSDecimalNumber(decimal: balance).stringValue
        account.currency = currency
        account.updatedAt = Date()
        
        try storage.save(bankAccount: account)
        
        let requestBody: [String: Any] = [
            "name": name,
            "balance": NSDecimalNumber(decimal: balance).stringValue,
            "currency": currency
        ]
        
        let body = try JSONSerialization.data(withJSONObject: requestBody)
        bankAccount = try await client.request(
            endpoint: "api/v1/accounts/\(account.id)",
            method: "PUT",
            body: body
        )
    }
    
    func updateBalance(with transaction: Transaction, category: Category) async throws {
        var account = try await fetchBankAccount()
        // Используем правильное преобразование String в Decimal
        guard let currentBalance = Decimal(string: account.balance, locale: Locale(identifier: "en_US")),
              let transactionAmount = Decimal(string: transaction.amount, locale: Locale(identifier: "en_US")) else {
            throw NSError(domain: "Invalid balance format", code: 0)
        }
        
        let newBalance = category.isIncome
            ? currentBalance + transactionAmount
            : currentBalance - transactionAmount
        
        try await updateBankAccount(
            name: account.name,
            balance: newBalance,
            currency: account.currency
        )
    }
    
    func reverseBalance(with transaction: Transaction, category: Category) async throws {
        var account = try await fetchBankAccount()
        guard let currentBalance = Decimal(string: account.balance, locale: Locale(identifier: "en_US")),
              let transactionAmount = Decimal(string: transaction.amount, locale: Locale(identifier: "en_US")) else {
            throw NSError(domain: "Invalid balance format", code: 0)
        }
        
        let newBalance = category.isIncome
            ? currentBalance - transactionAmount
            : currentBalance + transactionAmount
        
        account.balance = NSDecimalNumber(decimal: newBalance).stringValue
        account.updatedAt = Date()
        
        try await changeBankAccount(account)
    }

}

