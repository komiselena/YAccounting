//
//  TransactionResponse.swift
//  YAccounting
//
//  Created by Mac on 15.06.2025.
//
import SwiftUI

struct TransactionResponse: Codable {
    let id: Int
    var account: Account
    var category: Category
    var amount: Decimal
    var transactionDate: Date
    var comment: String
    var createdAt: Date
    var updatedAt: Date

}


struct Account: Codable{
    let id: Int
    let name: String
    let balance: Decimal
    let currency: String
}
