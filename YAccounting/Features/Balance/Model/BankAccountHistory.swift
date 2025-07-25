//
//  BankAccountHistory.swift
//  YAccounting
//
//  Created by Mac on 25.07.2025.
//
import SwiftUI

struct BankAccountHistory: Codable {
    let accountId: Int
    let accountName: String
    var currentBalance: Decimal
    var currency: String
    var history: [History]
    
    init(accountId: Int, accountName: String, currentBalance: Decimal, currency: String, history: [History]){
        self.accountId = accountId
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.currency = currency
        self.history = history
    }
    
    enum CodingKeys: String, CodingKey {
        case accountId
        case accountName
        case currentBalance
        case currency
        case history
    }


    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accountId = try container.decode(Int.self, forKey: .accountId)
        accountName = try container.decode(String.self, forKey: .accountName)
        
        let balanceString = try container.decode(String.self, forKey: .currentBalance)
        guard let decimalBalance = Decimal(string: balanceString, locale: Locale(identifier: "en_US")) else {
            throw DecodingError.dataCorruptedError(forKey: .currentBalance, in: container, debugDescription: "Cannot decode balance as Decimal")
        }
        currentBalance = decimalBalance
        
        currency = try container.decode(String.self, forKey: .currency)
        history = try container.decode([History].self, forKey: .history)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(accountName, forKey: .accountName)
        
        try container.encode(NSDecimalNumber(decimal: currentBalance).stringValue, forKey: .currentBalance)
        
        try container.encode(currency, forKey: .currency)
        try container.encode(history, forKey: .history)
    }


}


struct History: Codable, Identifiable {
    var id: Int
    var accountId: Int
    var changeType: String
    var previousState: HistoryState?
    var newState: HistoryState?
    var changeTimestamp: Date
    var createdAt: Date
    
    init(id: Int, accountId: Int, changeType: String, previousState: HistoryState, newState: HistoryState, changeTimestamp: Date, createdAt: Date) {
        self.id = id
        self.accountId = accountId
        self.changeType = changeType
        self.previousState = previousState
        self.newState = newState
        self.changeTimestamp = changeTimestamp
        self.createdAt = createdAt
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.accountId = try container.decode(Int.self, forKey: .accountId)
        self.changeType = try container.decode(String.self, forKey: .changeType)
        self.previousState = try container.decodeIfPresent(HistoryState.self, forKey: .previousState) // Используем decodeIfPresent
        self.newState = try container.decodeIfPresent(HistoryState.self, forKey: .newState) // Используем decodeIfPresent
        self.changeTimestamp = try container.decode(Date.self, forKey: .changeTimestamp)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    
}

struct HistoryState: Codable, Identifiable {
    var id: Int
    var name: String
    var balance: Decimal
    var currency: String
    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        let balanceString = try container.decode(String.self, forKey: .balance)
        guard let decimalBalance = Decimal(string: balanceString, locale: Locale(identifier: "en_US")) else {
            throw DecodingError.dataCorruptedError(forKey: .balance, in: container, debugDescription: "Cannot decode balance as Decimal")
        }
        balance = decimalBalance
        self.currency = try container.decode(String.self, forKey: .currency)
    }
}
