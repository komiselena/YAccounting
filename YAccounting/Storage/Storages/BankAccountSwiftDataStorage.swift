//
//  BankAccountSwiftDataStorage.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//


import Foundation
import SwiftData

@MainActor
final class BankAccountSwiftDataStorage {
    let container: ModelContainer
    let modelContext: ModelContext

    init() {
        do {
            let config = ModelConfiguration("BankAccountData", schema: Schema([BankAccountModel.self]))
            container = try ModelContainer(for: BankAccountModel.self, configurations: config)
            modelContext = ModelContext(container)
        } catch {
            fatalError("Failed to create CategoryData container: \(error)")
        }
    }

    
    func fetchBankAccount() throws -> BankAccount? {
        let descriptor = FetchDescriptor<BankAccountModel>()
        let results = try modelContext.fetch(descriptor)
        
        guard let first = results.first else { return nil }
        return first.toBankAccount()
    }
    
    func save(bankAccount: BankAccount) throws {
        let descriptor = FetchDescriptor<BankAccountModel>(
            predicate: #Predicate { $0.id == bankAccount.id }
        )
        let existing = try modelContext.fetch(descriptor).first
        
        if let existing = existing {
            existing.name = bankAccount.name
            existing.balance = Decimal(string: bankAccount.balance) ?? 0
            existing.currency = bankAccount.currency
            existing.updatedAt = bankAccount.updatedAt
        } else {
            let newModel = BankAccountModel(from: bankAccount)
            modelContext.insert(newModel)
        }
        
        try modelContext.save()
    }
    
    func deleteAll() throws {
        let descriptor = FetchDescriptor<BankAccountModel>()
        let accounts = try modelContext.fetch(descriptor)
        for account in accounts {
            modelContext.delete(account)
        }
        try modelContext.save()
    }
}

