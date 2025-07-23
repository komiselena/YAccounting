//
//  BalanceViewModel.swift
//  YAccounting
//
//  Created by Mac on 21.06.2025.
//

import Foundation
import Combine

@MainActor
final class BalanceViewModel: ObservableObject {
    private let bankAccountService: BankAccountsService
    private var cancellables = Set<AnyCancellable>()

    @Published var bankAccount: BankAccount?
    @Published var isLoading = false
    @Published var error: Error?

    @Published var currentCurrency: Currency = .RUB

    @Published var balanceScreenState: BalanceState = .view
    
    init(bankAccountService: BankAccountsService) {
        self.bankAccountService = bankAccountService
        
        bankAccountService.$bankAccount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newAccount in
                self?.bankAccount = newAccount
                if let currencyString = newAccount?.currency {
                    self?.currentCurrency = Currency(rawValue: currencyString) ?? .RUB
                }
            }
            .store(in: &cancellables)
        
    }

    func loadBankAccountData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            bankAccount = try await bankAccountService.fetchBankAccount(forceReload: true)
        } catch {
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
        
        do {
            try await bankAccountService.updateBankAccount(
                name: account.name,
                balance: newBalance,
                currency: account.currency
            )
            print("Balance update initiated successfully to: \(newBalance)")
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
            print("Currency update initiated successfully to: \(newCurrency)")
        }catch{
            print("Error updating currency: \(error)")
            self.error = error
        }
    }
    
    func recalculateBalance() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let categoriesService = CategoriesService()
            let categories = try await categoriesService.categories()
            
            let transactionService = TransactionService(
                accountsService: bankAccountService,
                categoriesService: categoriesService
            )
            
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            let transactions = try await transactionService.fetchTransactions(for: startDate...endDate)
            
            let transactionModels = transactions.map { $0.toTransaction() }
            try await bankAccountService.recalculateBalance(transactions: transactionModels, categories: categories)
            
            print("Balance recalculation initiated successfully")
        } catch {
            print("Error recalculating balance: \(error)")
            self.error = error
        }
    }
}


