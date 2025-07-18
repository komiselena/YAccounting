//
//  BankAccountEntity+CoreDataProperties.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//
//

import Foundation
import CoreData


extension BankAccountEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BankAccountEntity> {
        return NSFetchRequest<BankAccountEntity>(entityName: "BankAccountEntity")
    }

    @NSManaged public var updatedAt: Date?
    @NSManaged public var name: String?
    @NSManaged public var userId: Int64
    @NSManaged public var id: Int64
    @NSManaged public var createdAt: Date?
    @NSManaged public var currency: String?
    @NSManaged public var balance: NSDecimalNumber?

}

extension BankAccountEntity : Identifiable {

}
