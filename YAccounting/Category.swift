//
//  Category.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import Foundation
import SwiftUI

struct Category: Codable {
    let id: Int
    let name: String
    let emoji: Character
    let isIncome: Bool
    
    var direction: Direction {
        return isIncome ? .income : .outcome
    }

    init(id: Int, name: String, emoji: Character, isIncome: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        let emojiString = try container.decode(String.self, forKey: .emoji)
        guard emojiString.count == 1, let emojiChar = emojiString.first else {
            throw DecodingError.dataCorruptedError(forKey: .emoji, in: container, debugDescription: "emoji must be a single character")
        }
        emoji = emojiChar
        isIncome = try container.decode(Bool.self, forKey: .isIncome)

    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(isIncome, forKey: .isIncome)

    }
    
    
}

enum Direction {
    case income
    case outcome
}
