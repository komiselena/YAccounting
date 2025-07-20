//
//  BankAccount.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import Foundation
import SwiftUI

struct BankAccount: Codable {
    let id: Int
    var userId: Int
    var name: String
    var balance: String
    var currency: String
    var createdAt: Date?
    var updatedAt: Date?
    
}
