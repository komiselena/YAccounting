//
//  TransactionResponse+Map.swift
//  YAccounting
//
//  Created by Mac on 15.07.2025.
//

import Foundation


extension TransactionResponse {
    func toTransaction() -> Transaction {
        Transaction(
            id: id,
            accountId: account.id,
            categoryId: category.id,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}
