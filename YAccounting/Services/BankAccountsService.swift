//
//  BankAccountsService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation


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
}

