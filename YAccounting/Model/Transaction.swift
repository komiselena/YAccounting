//
//  Transaction.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import Foundation

struct Transaction: Codable {
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: Date
    let comment: String
}


extension Transaction {
    var jsonObject: Any {
        return [
            "accountId": self.accountId,
            "categoryId" : self.categoryId,
            "amount": NSDecimalNumber(decimal: self.amount).stringValue,
            "transactionDate": ISO8601DateFormatter().string(from: self.transactionDate),
            "comment" : self.comment
        ]
    }

    static func parse(jsonObject: Any) -> Transaction? {
        guard let jsonDict = jsonObject as? [String: Any] else {
            return nil
        }
        
        guard let accountId = jsonDict["accountId"] as? Int,
              let categoryId = jsonDict["categoryId"] as? Int,
              let amountString = jsonDict["amount"] as? String,
              let transactionDateString = jsonDict["transactionDate"] as? String,
              let comment = jsonDict["comment"] as? String
        else {
            return nil
        }
        
        guard let amount = Decimal(string: amountString),
              let transactionDate = ISO8601DateFormatter().date(from: transactionDateString)
        else {
            return nil
        }
        
        return Transaction(accountId: accountId, categoryId: categoryId, amount: amount, transactionDate: transactionDate, comment: comment)
        
    }
}

