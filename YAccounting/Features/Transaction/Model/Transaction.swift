//
//  Transaction.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import SwiftData
import SwiftUI

//@Model
struct Transaction: Codable, Equatable, Identifiable {
    let id: Int
    var accountId: Int
    var categoryId: Int
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    var createdAt: Date?
    var updatedAt: Date?
    
//    init(id: Int, accountId: Int, categoryId: Int, amount: Decimal, transactionDate: Date, comment: String? = nil, createdAt: Date, updatedAt: Date) {
//        self.id = id
//        self.accountId = accountId
//        self.categoryId = categoryId
//        self.amount = amount
//        self.transactionDate = transactionDate
//        self.comment = comment
//        self.createdAt = createdAt
//        self.updatedAt = updatedAt
//    }
    
    enum CodingKeys: String, CodingKey {
        case id, accountId, categoryId, amount, transactionDate, comment, createdAt, updatedAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        
        let amountString = NSDecimalNumber(decimal: amount).stringValue
        try container.encode(amountString, forKey: .amount)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(dateFormatter.string(from: transactionDate), forKey: .transactionDate)
        
        try container.encodeIfPresent(comment, forKey: .comment)
        
        if let createdAt = createdAt {
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        }
        if let updatedAt = updatedAt {
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
    }

}


