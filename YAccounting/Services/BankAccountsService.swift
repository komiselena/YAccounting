//
//  BankAccountsService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation
import SwiftData

@MainActor
final class BankAccountsService: @preconcurrency BankAccountsServiceProtocol {
    
    static let shared: BankAccountsService = BankAccountsService()
    
    private let client: NetworkClient
    private let storage = BankAccountSwiftDataStorage()
    
    @Published var bankAccount: BankAccount?
    
    init(
        client: NetworkClient = NetworkClient(),
        initialBankAccount: BankAccount? = nil
    ) {
        self.client = client
        self.bankAccount = initialBankAccount
    }
    
    func fetchBankAccount(forceReload: Bool) async throws -> BankAccount {
        if !NetworkStatusMonitor.shared.isConnected || !forceReload {
            if let localAccount = try? storage.fetchBankAccount() {
                print("Загружаем из SwiftData: \(localAccount)")
                self.bankAccount = localAccount
                return localAccount
            }
        }
        
        if NetworkStatusMonitor.shared.isConnected {
            do {
                let bankAccounts: [BankAccount] = try await client.request(endpoint: "api/v1/accounts", method: "GET")
                guard let selectedAccount = bankAccounts.first else {
                    print("No bank accounts found on server.")
                    throw NSError(domain: "BankAccountsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No bank accounts found on server."])
                }
                
                try storage.save(bankAccount: selectedAccount)
                self.bankAccount = selectedAccount
                print("FETCHED BANK ACCOUNT from network: \(selectedAccount)")
                return selectedAccount
            } catch {
                if let local = try? storage.fetchBankAccount() {
                    self.bankAccount = local
                    return local
                } else {
                    throw error 
                }
            }
        } else {
            throw NSError(domain: "BankAccountsService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No network connection and no local data."])
        }
    }
    
    func changeBankAccount(_ bankAccount: BankAccount) async throws {
        var updatedAccount = bankAccount
        updatedAccount.updatedAt = Date()
        
        try storage.save(bankAccount: updatedAccount)
        self.bankAccount = updatedAccount
        
        print("Bank account changed locally: \(updatedAccount.balance)")
        
        // Отправляем на сервер
        if NetworkStatusMonitor.shared.isConnected {
            do {
                let requestBody: [String: Any] = [
                    "name": updatedAccount.name,
                    "balance": NSDecimalNumber(decimal: updatedAccount.balance).stringValue,
                    "currency": updatedAccount.currency
                ]
                let body = try JSONSerialization.data(withJSONObject: requestBody)
                let _: BankAccount = try await client.request(
                    endpoint: "api/v1/accounts/\(updatedAccount.id)",
                    method: "PUT",
                    body: body
                )
                print("Account updated on server successfully: \(updatedAccount.balance)")
            } catch {
                print("Failed to update account on server: \(error)")
                throw error
            }
        }
    }
    
    func updateBankAccount(name: String, balance: Decimal, currency: String) async throws {
        guard var bankAccount = self.bankAccount else {
            bankAccount = try await fetchBankAccount(forceReload: false)
            return
        }
        
        bankAccount.name = name
        bankAccount.balance = balance
        bankAccount.currency = currency
        bankAccount.updatedAt = Date()
        
        if NetworkStatusMonitor.shared.isConnected {
            print("Updating account on server: \(balance)")
            let requestBody: [String: Any] = [
                "name": name,
                "balance": NSDecimalNumber(decimal: balance).stringValue,
                "currency": currency
            ]
            
            do {
                let body = try JSONSerialization.data(withJSONObject: requestBody)
                let updatedAccount: BankAccount = try await client.request(
                    endpoint: "api/v1/accounts/\(bankAccount.id)",
                    method: "PUT",
                    body: body
                )
                
                try storage.save(bankAccount: updatedAccount)
                self.bankAccount = updatedAccount
                print("Account updated on server successfully: \(updatedAccount.balance)")
            } catch {
                print("Failed to update account on server: \(error)")
                try storage.save(bankAccount: bankAccount)
                self.bankAccount = bankAccount
                throw error
            }
        } else {
            print("No network connection, saving account locally: \(balance)")
            try storage.save(bankAccount: bankAccount)
            self.bankAccount = bankAccount
        }
    }
    
    func updateBalanceForTransaction(_ transaction: Transaction, category: Category, isAdding: Bool) async throws {
        guard var bankAccount = self.bankAccount else { return }
        
        let amount = Decimal(string: transaction.amount) ?? 0
        let delta = category.isIncome ? amount : -amount
        let adjustment = isAdding ? delta : -delta
        
        bankAccount.balance += adjustment
        try await updateBankAccount(
            name: bankAccount.name,
            balance: bankAccount.balance,
            currency: bankAccount.currency
        )
    }
    
    
    func fetchBankAccountHistory(id: Int) async throws -> BankAccountHistory? {
        do {
            let bankAccountHistory: BankAccountHistory = try await client.request(endpoint: "api/v1/accounts/\(id)/history", method: "GET")
            
//            try storage.save(bankAccount: selectedAccount)
//            self.bankAccount = selectedAccount
//            print("FETCHED BANK ACCOUNT from network: \(selectedAccount)")
            print(bankAccountHistory)
            return bankAccountHistory
        } catch {
//            if let local = try? storage.fetchBankAccount() {
//                self.bankAccount = local
//                return local
//            } else {
            print(error)
                throw error
//            }
        }
    }
    
    
}

