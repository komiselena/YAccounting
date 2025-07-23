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
                print("Ошибка запроса к сети: \(error)")
                if let local = try? storage.fetchBankAccount() {
                    print("Загружаем из SwiftData (fallback): \(local)")
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
    
    func recalculateBalance(transactions: [Transaction], categories: [Category]) async throws {
        guard let bankAccount = self.bankAccount else {
            bankAccount = try await fetchBankAccount(forceReload: false)
            return
        }
        
        let initialBalance: Decimal = bankAccount.balance
        
        let calculatedBalance = transactions.reduce(initialBalance) { currentBalance, transaction in
            guard let category = categories.first(where: { $0.id == transaction.categoryId }),
                  let transactionAmount = Decimal(string: transaction.amount, locale: Locale(identifier: "en_US")) else {
                print("Warning: Could not process transaction \(transaction.id)")
                return currentBalance
            }
            
            let newBalance = category.isIncome
                ? currentBalance + transactionAmount
                : currentBalance - transactionAmount
            
            print("Transaction \(transaction.id): \(category.isIncome ? "+" : "-")\(transactionAmount) = \(newBalance)")
            return newBalance
        }
        
        print("Recalculated balance: \(calculatedBalance) (was: \(bankAccount.balance))")
        
        if calculatedBalance != bankAccount.balance {
            try await updateBankAccount(
                name: bankAccount.name,
                balance: calculatedBalance,
                currency: bankAccount.currency
            )
        }
    }
    
    func updateBalanceForTransaction(_ transaction: Transaction, category: Category, isAdding: Bool) async throws {
        var currentAccount: BankAccount
        if let cached = self.bankAccount {
            currentAccount = cached
        } else {
            currentAccount = try await fetchBankAccount(forceReload: false)
        }

        guard let transactionAmount = Decimal(string: transaction.amount, locale: Locale(identifier: "en_US")) else {
            throw NSError(domain: "Invalid transaction amount format", code: 0)
        }

        let balanceChange: Decimal = isAdding
            ? (category.isIncome ? transactionAmount : -transactionAmount)
            : (category.isIncome ? -transactionAmount : transactionAmount)

        let newBalance = currentAccount.balance + balanceChange

        print("Balance change for transaction \(transaction.id): \(balanceChange) (new balance: \(newBalance))")

        try await updateBankAccount(
            name: currentAccount.name,
            balance: newBalance,
            currency: currentAccount.currency
        )
    }
}


