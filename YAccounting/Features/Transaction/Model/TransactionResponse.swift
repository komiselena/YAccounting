//
//  TransactionResponse.swift
//  YAccounting
//
//  Created by Mac on 15.06.2025.
//
import SwiftUI

struct TransactionResponse: Codable {
    let id: Int
    var account: Account
    var category: Category
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, account, category, amount, transactionDate, comment, createdAt, updatedAt
    }
    
    init(id: Int, account: Account, category: Category, amount: Decimal, transactionDate: Date, comment: String? = "", createdAt: Date? = Date.now, updatedAt: Date? = Date.now) {
        self.id = id
        self.account = account
        self.category = category
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        account = try container.decode(Account.self, forKey: .account)
        category = try container.decode(Category.self, forKey: .category)
        comment = try? container.decode(String.self, forKey: .comment)
        transactionDate = try container.decode(Date.self, forKey: .transactionDate)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        updatedAt = try? container.decode(Date.self, forKey: .updatedAt)

        let amountString = try container.decode(String.self, forKey: .amount)
        guard let decimal = Decimal(string: amountString) else {
            throw DecodingError.dataCorruptedError(forKey: .amount, in: container, debugDescription: "Invalid decimal string for amount")
        }
        amount = decimal
    }
}

struct Account: Codable{
    let id: Int
    let name: String
    let balance: String
    let currency: String
    
    init(id: Int, name: String, balance: String, currency: String){
        self.id = id
        self.name = name
        self.balance = balance
        self.currency = currency
    }


}


