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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionsUpdate),
            name: .transactionsUpdated,
            object: nil
        )
    }
    
    @objc private func handleTransactionsUpdate() {
        Task { await loadBankAccountData() }
    }

    func loadBankAccountData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            bankAccount = try await bankAccountService.fetchBankAccount()
        }catch{
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
        guard var account = bankAccount else { return }
        account.balance = String(describing: newBalance)
        do{
            try await bankAccountService.changeBankAccount(account)
            bankAccount = account
        }catch{
            print("Error updating balance: \(error)")
        }
    }
    
    func updateCurrency(_ newCurrency: String) async {
        guard var account = bankAccount else { return }
        account.currency = newCurrency
        do{
            try await bankAccountService.changeBankAccount(account)
            bankAccount = account
        }catch{
            print("Error updating balance: \(error)")
        }
    }

    
}
