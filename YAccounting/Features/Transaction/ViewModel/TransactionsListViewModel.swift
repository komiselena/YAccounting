//
//  TransactionsListViewModel.swift
//  YAccounting
//
//  Created by Mac on 19.06.2025.
//

import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject {
    
    private let transactionService = TransactionService()
    private let categoriesService = CategoriesService()
    
    let direction: Direction

    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false

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
    
    
    init(direction: Direction){
        self.direction = direction
        
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

}
