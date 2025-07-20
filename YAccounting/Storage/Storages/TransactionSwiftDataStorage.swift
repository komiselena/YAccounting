//
//  TransactionSwiftDataStorage.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//

import Foundation
import SwiftData

protocol TransactionStorageProtocol {
    func fetchAllTransactions() async throws -> [Transaction]
    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction]
    func fetchTransaction(id: Int) async throws -> Transaction?
    func createTransaction(_ transaction: Transaction) async throws
    func editTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: Int) async throws
    func fetchPendingDeletions() async throws -> [Int]
    func clearDeletionMark(id: Int) async throws
}

@MainActor
final class TransactionSwiftDataStorage: TransactionStorageProtocol {
    let container: ModelContainer
    let modelContext: ModelContext

    init() {
        do {
            let config = ModelConfiguration("TransactionData", schema: Schema([TransactionModel.self]))
            container = try ModelContainer(for: TransactionModel.self, configurations: config)
            modelContext = ModelContext(container)
        } catch {
            fatalError("Failed to create ModelContainer for TransactionModel: \(error.localizedDescription)")
        }
    }
    
    func saveContext() throws {
    try modelContext.save()
    }



    func fetchAllTransactions() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionModel>(sortBy: [SortDescriptor(\.transactionDate, order: .reverse)])
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toTransaction() }
    }

    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        let startDate = period.lowerBound
        let endDate = period.upperBound
        let predicate = #Predicate<TransactionModel> {
            $0.transactionDate >= startDate && $0.transactionDate <= endDate
        }
        let descriptor = FetchDescriptor<TransactionModel>(predicate: predicate, sortBy: [SortDescriptor(\TransactionModel.transactionDate, order: .reverse)])
        let models = try modelContext.fetch(descriptor)
        return models.map { $0.toTransaction() }
    }

    func fetchTransaction(id: Int) async throws -> Transaction? {
        let predicate = #Predicate<TransactionModel> {
            $0.id == id
        }
        var descriptor = FetchDescriptor<TransactionModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        let models = try modelContext.fetch(descriptor)
        return models.first?.toTransaction()
    }

    func createTransaction(_ transaction: Transaction) async throws {
        let model = TransactionModel(from: transaction)
        modelContext.insert(model)
        print("transaction is inserted to model \(transaction)")
        try modelContext.save()
    }

    func editTransaction(_ transaction: Transaction) async throws {
        let predicate = #Predicate<TransactionModel> {
            $0.id == transaction.id
        }
        var descriptor = FetchDescriptor<TransactionModel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let model = try modelContext.fetch(descriptor).first {
            model.accountId = transaction.accountId
            model.categoryId = transaction.categoryId
            model.amount = transaction.decimalAmount
            model.transactionDate = transaction.transactionDate
            model.comment = transaction.comment
            model.updatedAt = Date()
            try modelContext.save()
        }
    }

    func deleteTransaction(id: Int) async throws {
        let predicate = #Predicate<TransactionModel> {
            $0.id == id
        }
        try modelContext.delete(model: TransactionModel.self, where: predicate)
        try modelContext.save()
    }
}


extension TransactionSwiftDataStorage {
    private var pendingDeletionsKey: String { "pendingDeletions" }
    
    func fetchPendingDeletions() async throws -> [Int] {
        UserDefaults.standard.array(forKey: pendingDeletionsKey) as? [Int] ?? []
    }
    
    func markTransactionForDeletion(id: Int) async throws {
        var deletions = try await fetchPendingDeletions()
        if !deletions.contains(id) {
            deletions.append(id)
            UserDefaults.standard.set(deletions, forKey: pendingDeletionsKey)
        }
        try await deleteTransaction(id: id)
    }
    
    func clearDeletionMark(id: Int) async throws {
        var deletions = try await fetchPendingDeletions()
        deletions.removeAll { $0 == id }
        UserDefaults.standard.set(deletions, forKey: pendingDeletionsKey)
    }
}
