//
//  Transaction.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import SwiftUI

struct Transaction: Codable, Equatable, Identifiable {
    let id: Int
    var accountId: Int
    var categoryId: Int
    var amount: String
    var transactionDate: Date
    var comment: String?
    var createdAt: Date?
    var updatedAt: Date?
        
    var decimalAmount: Decimal {
        return Decimal(string: amount) ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case accountId
        case categoryId
        case amount
        case transactionDate
        case comment
        case createdAt
        case updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(categoryId, forKey: .categoryId)
        
        try container.encode(amount, forKey: .amount)
        
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


