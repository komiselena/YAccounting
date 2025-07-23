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
        balance: Decimal(100000.9),
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
            print("FETCHED BANK ACCOUNT: \(selectedAccount)")
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
        
        // ИСПРАВЛЕНО: Обновляем и локальную переменную
        self.bankAccount = updatedAccount
        mockBankAccount = updatedAccount
        
        try storage.save(bankAccount: updatedAccount)
        
        print("Bank account changed locally: \(updatedAccount.balance)")
    }
    
    func updateBankAccount(name: String, balance: Decimal, currency: String) async throws {
        var account = try await fetchBankAccount()
        account.name = name
        account.balance = balance
        account.currency = currency
        account.updatedAt = Date()
        
        // ИСПРАВЛЕНО: Сначала сохраняем локально
        try storage.save(bankAccount: account)
        self.bankAccount = account
        
        print("Updating account on server: \(balance)")
        
        let requestBody: [String: Any] = [
            "name": name,
            "balance": NSDecimalNumber(decimal: balance).stringValue,
            "currency": currency
        ]
        
        do {
            let body = try JSONSerialization.data(withJSONObject: requestBody)
            let updatedAccount: BankAccount = try await client.request(
                endpoint: "api/v1/accounts/\(account.id)",
                method: "PUT",
                body: body
            )
            
            // ИСПРАВЛЕНО: Обновляем локальные данные после успешного обновления на сервере
            bankAccount = updatedAccount
            try storage.save(bankAccount: updatedAccount)
            
            print("Account updated on server successfully: \(updatedAccount.balance)")
        } catch {
            print("Failed to update account on server: \(error)")
            // Оставляем локальные изменения даже если сервер недоступен
            throw error
        }
    }
    
    // НОВЫЙ МЕТОД: Пересчет баланса на основе всех транзакций
    func recalculateBalance(transactions: [Transaction], categories: [Category]) async throws {
        var account = try await fetchBankAccount()
        
        // ИСПРАВЛЕНО: Начинаем с нулевого баланса для полного пересчета
        // Или можно использовать начальный баланс, если он задан
        let initialBalance: Decimal = 0 // Можно изменить на account.balance если нужно сохранить начальный баланс
        
        // Вычисляем итоговый баланс на основе всех транзакций
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
        
        print("Recalculated balance: \(calculatedBalance) (was: \(account.balance))")
        
        // Обновляем баланс только если он изменился
        if calculatedBalance != account.balance {
            try await updateBankAccount(
                name: account.name,
                balance: calculatedBalance,
                currency: account.currency
            )
        }
    }
    
    // УПРОЩЕННЫЙ МЕТОД: Обновление баланса для одной транзакции
    func updateBalanceForTransaction(_ transaction: Transaction, category: Category, isAdding: Bool) async throws {
        var account = try await fetchBankAccount()
        
        guard let transactionAmount = Decimal(string: transaction.amount, locale: Locale(identifier: "en_US")) else {
            throw NSError(domain: "Invalid transaction amount format", code: 0)
        }
        
        let balanceChange: Decimal
        if isAdding {
            // Добавляем транзакцию
            balanceChange = category.isIncome ? transactionAmount : -transactionAmount
        } else {
            // Удаляем транзакцию
            balanceChange = category.isIncome ? -transactionAmount : transactionAmount
        }
        
        let newBalance = account.balance + balanceChange
        
        print("Balance change for transaction \(transaction.id): \(balanceChange) (new balance: \(newBalance))")
        
        try await updateBankAccount(
            name: account.name,
            balance: newBalance,
            currency: account.currency
        )
    }
}

