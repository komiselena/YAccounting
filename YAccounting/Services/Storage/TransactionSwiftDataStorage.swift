import Foundation
import SwiftData

protocol TransactionStorageProtocol {
//    func fetchAllTransactions() async throws -> [Transaction]
//    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction]
//    func fetchTransaction(id: Int) async throws -> Transaction?
    func createTransaction(_ transaction: Transaction) async throws
    func editTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: Int) async throws
}

@MainActor
final class TransactionSwiftDataStorage: TransactionStorageProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() {
        do {
            self.modelContainer = try ModelContainer(for: TransactionModel.self)
            self.modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to create ModelContainer for TransactionModel: \(error.localizedDescription)")
        }
    }

//    func fetchAllTransactions() async throws -> [Transaction] {
//        let descriptor = FetchDescriptor<TransactionModel>(sortBy: [SortDescriptor(\TransactionModel.transactionDate, order: .reverse)])
//        let models = try modelContext.fetch(descriptor)
//        return models.map { $0.toTransaction() }
//    }
//
//    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [Transaction] {
//        let startDate = period.lowerBound
//        let endDate = period.upperBound
//        let predicate = #Predicate<TransactionModel> {
//            $0.transactionDate >= startDate && $0.transactionDate <= endDate
//        }
//        let descriptor = FetchDescriptor<TransactionModel>(predicate: predicate, sortBy: [SortDescriptor(\TransactionModel.transactionDate, order: .reverse)])
//        let models = try modelContext.fetch(descriptor)
//        return models.map { $0.toTransaction() }
//    }
//
//    func fetchTransaction(id: Int) async throws -> Transaction? {
//        let predicate = #Predicate<TransactionModel> {
//            $0.id == id
//        }
//        var descriptor = FetchDescriptor<TransactionModel>(predicate: predicate)
//        descriptor.fetchLimit = 1
//        let models = try modelContext.fetch(descriptor)
//        return models.first?.toTransaction()
//    }

    func createTransaction(_ transaction: Transaction) async throws {
        let model = TransactionModel(from: transaction)
        modelContext.insert(model)
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


