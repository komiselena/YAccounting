//
//  TransactionEntity+CoreDataProperties.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//
//

import Foundation
import CoreData


extension TransactionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionEntity> {
        return NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
    }

    @NSManaged public var id: Int64
    @NSManaged public var updatedAt: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var comment: String?
    @NSManaged public var transactionDate: Date?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var categoryId: Int64
    @NSManaged public var accountId: Int64

}

extension TransactionEntity : Identifiable {

}
