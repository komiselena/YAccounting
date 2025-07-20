//
//  TransactionEntity+CoreDataClass.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//
//

import Foundation
import CoreData

@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject {
    func toTransaction() -> Transaction {
        return Transaction(
            id: Int(id),
            accountId: Int(accountId),
            categoryId: Int(categoryId),
            amount: amount?.stringValue ?? "0",
            transactionDate: transactionDate ?? Date(),
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

}
