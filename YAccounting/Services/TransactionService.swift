//
//  TransactionService.swift
//  YAccounting
//
//  Created by Mac on 08.06.2025.
//

import Foundation
import SwiftData

@MainActor
final class TransactionService: ObservableObject, @unchecked Sendable {
    private let client: NetworkClient
    private var storage: TransactionStorageProtocol {
        StorageSettings.shared.currentStorage == .coreData
            ? TransactionCoreDataStorage()
            : TransactionSwiftDataStorage()
    }
    private let backupStorage: TransactionStorageProtocol
    private let accountsService: BankAccountsServiceProtocol
    private let categoriesService: CategoriesServiceProtocol
    @Published var isOfflineMode: Bool = false

    init(
        client: NetworkClient = NetworkClient(),
        storage: TransactionStorageProtocol? = nil,
        backupStorage: TransactionStorageProtocol? = nil,
        accountsService: BankAccountsServiceProtocol,
        categoriesService: CategoriesServiceProtocol
    ) {
        self.client = client
        self.accountsService = accountsService
        self.categoriesService = categoriesService

        if let storage = storage, let backupStorage = backupStorage {
            self.backupStorage = backupStorage
        } else {
            self.backupStorage = TransactionSwiftDataStorage()
        }
    }

    func fetchTransactions(for period: ClosedRange<Date>) async throws -> [TransactionResponse] {
        if !NetworkStatusMonitor.shared.isConnected {
            print("⚠️ Offline mode activated")
            print("📦 Загружаем транзакции из локального хранилища (offline)")

            let localTransactions = try await storage.fetchTransactions(for: period)
            return try await localTransactions.concurrentMap { transaction in
                let account = try await self.accountsService.fetchBankAccount()
                let category = try await self.categoriesService.categories().first(where: { $0.id == transaction.categoryId })
                return transaction.toTransactionResponse(
                    account: Account(id: account.id, name: account.name, balance: account.balance, currency: account.currency),
                    category: category ?? Category(id: 0, name: "Uncategorized", emoji: "🔎", isIncome: false)
                )
            }
        }

        try await syncBackupTransactions()

        let bankAccount = try await accountsService.fetchBankAccount()

        do {
            let endpoint = "api/v1/transactions/account/\(bankAccount.id)/period?startDate=\(period.lowerBound.formatPeriod())&endDate=\(period.upperBound.formatPeriod())"
            let serverResponses = try await client.request(endpoint: endpoint) as [TransactionResponse]
            try await saveNewTransactions(serverResponses)
            return serverResponses
        } catch {
            let localTransactions = try await storage.fetchTransactions(for: period)
            let backupTransactions = try await backupStorage.fetchTransactions(for: period)
            let combined = (localTransactions + backupTransactions)
            let uniqueTransactions = combined.unique(by: \.id)

            return try await uniqueTransactions.concurrentMap { transaction in
                let account = try await self.accountsService.fetchBankAccount()
                let category = try await self.categoriesService.categories().first(where: { $0.id == transaction.categoryId })
                return transaction.toTransactionResponse(
                    account: Account(id: account.id, name: account.name, balance: account.balance, currency: account.currency),
                    category: category ?? Category(id: 0, name: "Uncategorized", emoji: "🔎", isIncome: false)
                )
            }
        }
    }

    private func syncBackupTransactions() async throws {
        let unsyncedTransactions = try await backupStorage.fetchAllTransactions()
        let deletions = try await backupStorage.fetchPendingDeletions() 
        
        print("🔁 Синхронизируем изменения: \(unsyncedTransactions.count) новых, \(deletions.count) на удаление")

        for transaction in unsyncedTransactions {
            do {
                try await syncTransaction(transaction)
                try await backupStorage.deleteTransaction(id: transaction.id)
            } catch {
                print("Failed to sync transaction \(transaction.id): \(error)")
            }
        }
        
        for id in deletions {
            do {
                let endpoint = "api/v1/transactions/\(id)"
                let _: EmptyResponse = try await client.request(endpoint: endpoint, method: "DELETE")
                try await backupStorage.clearDeletionMark(id: id)
            } catch {
                print("Failed to sync deletion for transaction \(id): \(error)")
            }
        }
    }

    private func syncTransaction(_ transaction: Transaction) async throws {
        if try await storage.fetchTransaction(id: transaction.id) != nil {
            try await editTransaction(transaction, isSync: true)
        } else {
//            try await createTransaction(transaction, isSync: true)
        }
    }

    private func saveNewTransactions(_ transactions: [TransactionResponse]) async throws {
        for transactionResponse in transactions {
            let transaction = transactionResponse.toTransaction()
            if try await storage.fetchTransaction(id: transaction.id) == nil {
                try await storage.createTransaction(transaction)
            }
        }
    }

    func createTransaction(_ transaction: Transaction, isSync: Bool = false) async throws {
        let bankAccount = try await accountsService.fetchBankAccount()

        do {
            if !NetworkStatusMonitor.shared.isConnected {
                try await backupStorage.createTransaction(transaction)
                return
            }
            
            let endpoint = "api/v1/transactions"
            let requestBody: [String: Any] = [
                "accountId": bankAccount.id,
                "categoryId": transaction.categoryId,
                "amount": transaction.amount,
                "transactionDate": ISO8601DateFormatter().string(from: transaction.transactionDate),
                "comment": transaction.comment ?? ""
            ]
            let body = try JSONSerialization.data(withJSONObject: requestBody)
            let response: Transaction = try await client.request(endpoint: endpoint, method: "POST", body: body)
            try await storage.createTransaction(response)
            try? await backupStorage.deleteTransaction(id: transaction.id)
            if !isSync {
                NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
            }
        } catch {
            if error.isNetworkError {
                try await backupStorage.createTransaction(transaction)
            } else {
                throw error
            }
        }
    }

    func createNewBankAccount() async throws {
        let endpoint = "api/v1/accounts"
        let requestBody: [String: Any] = [
            "name": "Новый счет",
            "balance": "10000",
            "currency": "RUB"
        ]
        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let response: BankAccount = try await client.request(endpoint: endpoint, method: "POST", body: body)
        print(response)

    }

    func editTransaction(_ transaction: Transaction, isSync: Bool = false) async throws {
        let bankAccount = try await accountsService.fetchBankAccount()

        do {
            let endpoint = "api/v1/transactions/\(transaction.id)"
            let requestBody: [String: Any] = [
                "accountId": bankAccount.id,
                "categoryId": transaction.categoryId,
                "amount": transaction.amount,
                "transactionDate": ISO8601DateFormatter().string(from: transaction.transactionDate),
                "comment": transaction.comment ?? ""
            ]
            let body = try JSONSerialization.data(withJSONObject: requestBody)
            let _: EmptyResponse = try await client.request(endpoint: endpoint, method: "PUT", body: body)
            try await storage.editTransaction(transaction)
            try? await backupStorage.deleteTransaction(id: transaction.id)
            if !isSync {
                NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
            }
        } catch {
            try await backupStorage.editTransaction(transaction)
            throw error
        }
    }

    func deleteTransaction(id: Int) async throws {
        do {
            if !NetworkStatusMonitor.shared.isConnected {
                try await storage.deleteTransaction(id: id)
                NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
                return
            }
            
            let endpoint = "api/v1/transactions/\(id)"
            let _: EmptyResponse = try await client.request(endpoint: endpoint, method: "DELETE")
            try await storage.deleteTransaction(id: id)
            try? await backupStorage.deleteTransaction(id: id)
            NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
        } catch {
            if error.isNetworkError {
                try await storage.deleteTransaction(id: id)
            } else {
                throw error
            }
        }
    }}

extension Notification.Name {
    static let transactionsUpdated = Notification.Name("transactionsUpdated")
}

struct EmptyResponse: Decodable {}

extension Sequence {
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}

extension Array {
    func concurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        try await withThrowingTaskGroup(of: T.self) { group in
            for element in self {
                group.addTask {
                    try await transform(element)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }
}

extension Transaction: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }
}

extension Error {
    var isNetworkError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut
        ].contains(nsError.code)
    }
}
