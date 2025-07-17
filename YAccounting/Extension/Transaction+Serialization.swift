//
//  Transaction+EXT.swift
//  YAccounting
//
//  Created by Mac on 15.06.2025.
//
import SwiftUI

extension Transaction {
    var jsonObject: Any {
        return [
            "id": self.id,
            "accountId": self.accountId,
            "categoryId": self.categoryId,
            "amount": self.amount,
            "transactionDate": ISO8601DateFormatter().string(from: self.transactionDate),
            "comment": self.comment,
            "createdAt": ISO8601DateFormatter().string(from: self.createdAt ?? Date.now),
            "updatedAt": ISO8601DateFormatter().string(from: self.updatedAt ?? Date.now)

        ]
    }

    static func parse(jsonObject: Any) -> Transaction? {
        guard let jsonDict = jsonObject as? [String: Any] else {
            return nil
        }
        
        guard let id = jsonDict["id"] as? Int,
              let accountId = jsonDict["accountId"] as? Int,
              let categoryId = jsonDict["categoryId"] as? Int,
              let amountString = jsonDict["amount"] as? String,
              let transactionDateString = jsonDict["transactionDate"] as? String,
              let comment = jsonDict["comment"] as? String,
              let createdAtString = jsonDict["createdAt"] as? String,
              let updatedAtString = jsonDict["updatedAt"] as? String else {
            return nil
        }
        
        guard let amount = Decimal(string: amountString),
              let transactionDate = ISO8601DateFormatter().date(from: transactionDateString),
              let createdAt = ISO8601DateFormatter().date(from: createdAtString),
              let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) else {
            return nil
        }
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

}
