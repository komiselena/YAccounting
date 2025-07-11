//
//  BankAccountsServiceProtocol.swift
//  YAccounting
//
//  Created by Mac on 28.06.2025.
//

import Foundation

protocol BankAccountsServiceProtocol {
    
    func fetchBankAccount() async throws -> BankAccount
    func changeBankAccount(_ bankAccount: BankAccount) async throws
    
}
