
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
    let userId: Int
    let name: String
    let balance: Decimal
    let currency: String
    let createdAt: Date
    let updatedAt: Date
    
}
