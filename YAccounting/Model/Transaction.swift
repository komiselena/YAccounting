//
//  Transaction.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import Foundation

struct Transaction: Codable {
    let id: Int
    let account: Account
    let category: Category
    let amount: Decimal
    let transactionDate: Date
    let comment: String
    let createdAt: Date
    let updatedAt: Date

    
    struct Account: Codable{
        let id: Int
        let name: String
        let balance: Decimal
        let currency: String
    }

}



extension Transaction {
    var jsonObject: Any {
        return [
            "id": self.id,
            "account": [
                "id": self.account.id,
                "name": self.account.name,
                "balance": NSDecimalNumber(decimal: self.account.balance).stringValue,
                "currency": self.account.currency
            ],
            "category": [
                "id": self.category.id,
                "name": self.category.name,
                "emoji": String(self.category.emoji),
                "isIncome": self.category.isIncome
            ],
            "amount": NSDecimalNumber(decimal: self.amount).stringValue,
            "transactionDate": ISO8601DateFormatter().string(from: self.transactionDate),
            "comment" : self.comment,
            "createdAt": ISO8601DateFormatter().string(from: self.createdAt),
            "updatedAt": ISO8601DateFormatter().string(from: self.updatedAt),

        ]
    }

    static func parse(jsonObject: Any) -> Transaction? {
        guard let jsonDict = jsonObject as? [String: Any] else {
            return nil
        }
        
        guard let id = jsonDict["id"] as? Int,
              let accountDict = jsonDict["account"] as? [String: Any],
              let categoryDict = jsonDict["category"] as? [String: Any],
              let amountString = jsonDict["amount"] as? String,
              let transactionDateString = jsonDict["transactionDate"] as? String,
              let comment = jsonDict["comment"] as? String,
              let createdAtString = jsonDict["createdAt"] as? String,
              let updatedAtString = jsonDict["updatedAt"] as? String else {
            return nil
        }
        
        guard let accountId = accountDict["id"] as? Int,
              let accountName = accountDict["name"] as? String,
              let accountBalanceString = accountDict["balance"] as? String,
              let accountCurrency = accountDict["currency"] as? String,
              let accountBalance = Decimal(string: accountBalanceString) else {
            return nil
        }
        let account = Account(id: accountId, name: accountName, balance: accountBalance, currency: accountCurrency)

        guard let categoryId = categoryDict["id"] as? Int,
              let categoryName = categoryDict["name"] as? String,
              let emojiString = categoryDict["emoji"] as? String,
              let emojiChar = emojiString.first,
              let isIncome = categoryDict["isIncome"] as? Bool else {
            return nil
        }
        let category = Category(id: categoryId, name: categoryName, emoji: emojiChar, isIncome: isIncome)

        guard let amount = Decimal(string: amountString),
              let transactionDate = ISO8601DateFormatter().date(from: transactionDateString),
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString)


        else {
            return nil
        }
        
        return Transaction(
            id: id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

    }
}

