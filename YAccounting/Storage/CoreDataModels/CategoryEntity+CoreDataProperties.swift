//
//  CategoryEntity+CoreDataProperties.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//
//

import Foundation
import CoreData


extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var emoji: String?
    @NSManaged public var name: String?
    @NSManaged public var id: Int64
    @NSManaged public var isIncome: Bool

}

extension CategoryEntity : Identifiable {

}
