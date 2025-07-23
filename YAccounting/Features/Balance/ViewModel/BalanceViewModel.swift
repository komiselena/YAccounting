//
//  BalanceViewModel.swift
//  YAccounting
//
//  Created by Mac on 21.06.2025.
//

import Foundation

@MainActor
final class BalanceViewModel: ObservableObject {
    private let bankAccountService = BankAccountsService()
    @Published var bankAccount: BankAccount?
    @Published var isLoading = false
    @Published var error: Error?

    @Published var currentCurrency: Currency = .RUB

    @Published var balanceScreenState: BalanceState = .view
    
    init() {
        Task {
            await loadBankAccountData()
        }
    }

    func loadBankAccountData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            bankAccount = try await bankAccountService.fetchBankAccount(forceReload: false)
            if let currencyString = bankAccount?.currency {
                currentCurrency = Currency(rawValue: currencyString) ?? .RUB
            }
            print("Loaded bank account: \(bankAccount?.balance ?? 0)")
        } catch {
            print("Error loading bank account: \(error)")
            self.error = error
        }
    }
    
    func saveBankAccountData() async {
        guard let account = bankAccount else { return }
        do {
            try await bankAccountService.changeBankAccount(account)
        } catch {
            print("Error saving bank account: \(error)")
        }
    }

    func updateBalance(_ newBalance: Decimal) async {
        guard let account = bankAccount else {
            print("No bank account to update")
            return
        }
        
        print("Updating balance to: \(newBalance)")
        
        do {
            try await bankAccountService.updateBankAccount(
                name: account.name,
                balance: newBalance,
                currency: account.currency
            )
            // ИСПРАВЛЕНО: Обновляем локальный объект сразу после успешного обновления
            var updatedAccount = account
            updatedAccount.balance = newBalance
            updatedAccount.updatedAt = Date()
            bankAccount = updatedAccount
            
            print("Balance updated successfully to: \(newBalance)")
        } catch {
            print("Error updating balance: \(error)")
            self.error = error
        }
    }

    func updateCurrency(_ newCurrency: String) async {
        guard var account = bankAccount else { return }
        account.currency = newCurrency
        do{
            try await bankAccountService.changeBankAccount(account)
            bankAccount = account
            currentCurrency = Currency(rawValue: newCurrency) ?? .RUB
        }catch{
            print("Error updating currency: \(error)")
        }
    }
    
    // НОВЫЙ МЕТОД: Принудительный пересчет баланса на основе всех транзакций
    func recalculateBalance() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Получаем все транзакции и категории для пересчета
            let categoriesService = CategoriesService()
            let categories = try await categoriesService.categories()
            
            // Здесь нужно получить все транзакции для аккаунта
            // Для этого создадим временный TransactionService
            let transactionService = TransactionService(
                accountsService: bankAccountService,
                categoriesService: categoriesService
            )
            
            // Получаем все транзакции за большой период (например, за последний год)
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            let transactions = try await transactionService.fetchTransactions(for: startDate...endDate)
            
            // Пересчитываем баланс
            let transactionModels = transactions.map { $0.toTransaction() }
            try await bankAccountService.recalculateBalance(transactions: transactionModels, categories: categories)
            
            // Перезагружаем данные аккаунта
            await loadBankAccountData()
            
            print("Balance recalculated successfully")
        } catch {
            print("Error recalculating balance: \(error)")
            self.error = error
        }
    }
}


