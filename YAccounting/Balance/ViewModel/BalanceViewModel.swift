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

    @Published var currentCurrency: Currency = .RUB

    @Published var balanceScreenState: BalanceState = .view

    func loadBankAccountData() async {
        do {
            bankAccount = try await bankAccountService.fetchBankAccount()
        }catch{
            print("Error loading bank account data: \(error)")
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
        account.balance = newBalance
        do{
            try await bankAccountService.changeBankAccount(account)
            bankAccount = account
        }catch{
            print("Error updating balance: \(error)")
        }
    }
    
    
}
