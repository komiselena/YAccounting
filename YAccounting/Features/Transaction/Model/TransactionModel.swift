//
//  TransactionModel.swift
//  YAccounting
//
//  Created by Mac on 17.07.2025.
//

import SwiftData
import Foundation

@Model
final class TransactionModel{
    @Attribute(.unique) var id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date?
    var updatedAt: Date?
    var isSynced: Bool

    init(id: Int, accountId: Int, categoryId: Int, amount: Decimal, transactionDate: Date, comment: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil, isSynced: Bool = false) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
    }
    
    convenience init(from transaction: Transaction) {
        self.init(
            id: transaction.id,
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: Decimal(string: transaction.amount) ?? 0,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment,
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt,
            isSynced: false
        )
    }
    
    func toTransaction() -> Transaction {
        Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: String(describing: amount),
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
}
