//
//  BankAccountsService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation

final class BankAccountsService {
    
    private var mockBankAccount: BankAccount = BankAccount(id: 1, userId: 1, name: "main", balance: 100000.9, currency: "RUB", createdAt: Date(), updatedAt: Date())
    
    func fetchBankAccount() async throws -> BankAccount {
        return mockBankAccount
    }
    
    
    func changeBankAccount(_ bankAccount: BankAccount) async throws {
        mockBankAccount = bankAccount
    }
    
}
