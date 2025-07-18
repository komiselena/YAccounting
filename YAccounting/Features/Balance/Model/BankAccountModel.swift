//
//  BankAccountModel.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//


import Foundation
import SwiftData

@Model
final class BankAccountModel {
    @Attribute(.unique) var id: Int
    var userId: Int
    var name: String
    var balance: Decimal
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?
    
    init(
        id: Int,
        userId: Int,
        name: String,
        balance: Decimal,
        currency: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    convenience init(from bankAccount: BankAccount) {
        self.init(
            id: bankAccount.id,
            userId: bankAccount.userId,
            name: bankAccount.name,
            balance: Decimal(string: bankAccount.balance) ?? 0,
            currency: bankAccount.currency,
            createdAt: bankAccount.createdAt,
            updatedAt: bankAccount.updatedAt
        )
    }
    
    func toBankAccount() -> BankAccount {
        BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: String(describing: balance),
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
