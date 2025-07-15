//
//  BankAccountsService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation

final class BankAccountsService: BankAccountsServiceProtocol {
    
    private var mockBankAccount: BankAccount = BankAccount(id: 1, userId: 1, name: "main", balance: "100000.9", currency: "RUB", createdAt: Date(), updatedAt: Date())
    
    var bankAccount: BankAccount?
    
    func fetchBankAccount() async throws -> BankAccount {
        do{
            let bankAccounts = try await NetworkClient.shared.fetchDecodeData(enpointValue: "api/v1/accounts", dataType: BankAccount.self)
            bankAccount = bankAccounts.first ?? mockBankAccount
            print(bankAccount as Any)
            return bankAccount ?? mockBankAccount
        }catch{
            print (error)
        }

        return mockBankAccount
    }
    
    
    func changeBankAccount(_ bankAccount: BankAccount) async throws {
        var updatedAccunt = bankAccount
        updatedAccunt.updatedAt = Date()
        mockBankAccount = updatedAccunt
    }
    
}
