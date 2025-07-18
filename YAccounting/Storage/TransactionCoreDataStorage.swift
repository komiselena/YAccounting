//
//  TransactionCoreDataStorage.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//


import CoreData

@MainActor
final class TransactionCoreDataStorage: TransactionStorageProtocol {
    private let context: NSManagedObjectContext
    private let pendingDeletionsKey = "pendingDeletions"

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Основные методы
    
    func fetchAllTransactions() async throws -> [Transaction] {
        let request = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.transactionDate, ascending: false)]
        let entities = try context.fetch(request)
        return entities.map { $0.toTransaction() }
    }

    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "transactionDate >= %@ AND transactionDate <= %@",
            period.lowerBound as NSDate,
            period.upperBound as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.transactionDate, ascending: false)]
        let entities = try context.fetch(request)
        return entities.map { $0.toTransaction() }
    }

    func fetchTransaction(id: Int) async throws -> Transaction? {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        return try context.fetch(request).first?.toTransaction()
    }

    func createTransaction(_ transaction: Transaction) async throws {
        let entity = TransactionEntity(context: context)
        entity.id = Int64(transaction.id)
        entity.accountId = Int64(transaction.accountId)
        entity.categoryId = Int64(transaction.categoryId)
        entity.amount = NSDecimalNumber(string: transaction.amount)
        entity.transactionDate = transaction.transactionDate
        entity.comment = transaction.comment
        entity.createdAt = transaction.createdAt ?? Date()
        entity.updatedAt = Date()
        try context.save()
    }

    func editTransaction(_ transaction: Transaction) async throws {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", transaction.id)
        request.fetchLimit = 1
        
        if let entity = try context.fetch(request).first {
            entity.accountId = Int64(transaction.accountId)
            entity.categoryId = Int64(transaction.categoryId)
            entity.amount = NSDecimalNumber(string: transaction.amount)
            entity.transactionDate = transaction.transactionDate
            entity.comment = transaction.comment
            entity.updatedAt = Date()
            try context.save()
        }
    }

    func deleteTransaction(id: Int) async throws {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Методы для отложенного удаления
    
    func fetchPendingDeletions() async throws -> [Int] {
        UserDefaults.standard.array(forKey: pendingDeletionsKey) as? [Int] ?? []
    }

    func clearDeletionMark(id: Int) async throws {
        var deletions = try await fetchPendingDeletions()
        deletions.removeAll { $0 == id }
        UserDefaults.standard.set(deletions, forKey: pendingDeletionsKey)
    }
}
