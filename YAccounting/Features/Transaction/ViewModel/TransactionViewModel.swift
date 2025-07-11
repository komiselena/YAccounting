//
//  TransactionViewModel.swift
//  YAccounting
//
//  Created by Mac on 19.06.2025.
//

import Foundation

@MainActor
final class TransactionViewModel: ObservableObject {
    
    private let transactionService = TransactionService()
    private let categoriesService = CategoriesService()
    
    let direction: Direction
    var transaction: Transaction?
    
    @Published var transactionScreenMode: TransactionMode?

    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    
    @Published var showTransactionView = false

    @Published var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var endDate = Date()
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
        return start...end
    }

    var totalAmount: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    @Published var error: Error?

    @Published var sortOption: SortOption = .byDate
    
    @Published var selectedCategory: Category?
    @Published var amountString: String = ""
    @Published var date: Date = Date.now
    @Published var comment: String = ""
    @Published var showValidationAlert = false
    @Published var showDeleteConfirmation = false
    
    private var isFormValid: Bool {
        selectedCategory != nil && !amountString.isEmpty && Decimal(string: amountString) != nil
    }
        

    init(direction: Direction, transaction: Transaction? = nil) {
        self.direction = direction
        self.transaction = transaction
    }

    func loadData() async {
        isLoading = true
        do {
            categories = try await categoriesService.categories()
            let allTransactions = try await transactionService.fetchTransactions(for: dateRange)
            transactions = allTransactions.filter { transaction in
                guard let category = categories.first(where: { $0.id == transaction.categoryId }) else { return false }
                return category.direction == direction
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }
        
    func loadInitialData() async {
        isLoading = true
        await loadData()
        
        if transactionScreenMode == .edit, let transaction = transaction {
            selectedCategory = categories.first { $0.id == transaction.categoryId }
            amountString = transaction.amount.description
            date = transaction.transactionDate
            comment = transaction.comment ?? ""
        } else {
            selectedCategory = categories.first { $0.direction == direction }
        }
        isLoading = false
    }
    
    func saveTransaction() {
        guard isFormValid else {
            showValidationAlert = true
            return
        }
        
        guard let selectedCategory = selectedCategory,
              let amount = Decimal(string: amountString) else { return }
        
        let transaction = Transaction(
            id: transactionScreenMode == .edit ? transaction?.id ?? 0 : 0,
            accountId: 1,
            categoryId: selectedCategory.id,
            amount: amount,
            transactionDate: date,
            comment: comment.isEmpty ? nil : comment,
            createdAt: transactionScreenMode == .edit ? transaction?.createdAt ?? Date.now : Date.now,
            updatedAt: Date.now
        )
        
        Task {
            isLoading = true
            if transactionScreenMode == .edit {
                do {
                    try await transactionService.editTransaction(transaction)
                    await loadData()
                    
                } catch {
                    self.error = error
                }
            } else {
                do {
                    try await transactionService.createTransaction(transaction)
                    await loadData()
                } catch {
                    self.error = error
                }
            }
            amountString = ""
            comment = ""
            showTransactionView = false
            isLoading = false
        }
    }
    
    func deleteTransaction() async {
        guard let transaction = transaction else { return }
        isLoading = true
        do {
            try await transactionService.deleteTransaction(transaction)
            await loadData()
        } catch {
            self.error = error
        }
        amountString = ""
        comment = ""
        showTransactionView = false
        isLoading = false
    }



}
