//
//  Transaction.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import Foundation

struct Transaction: Codable, Equatable, Identifiable {
    let id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date
    var updatedAt: Date
}


