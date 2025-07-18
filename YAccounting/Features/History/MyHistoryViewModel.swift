//
//  MyHistoryViewModel.swift
//  YAccounting
//
//  Created by Mac on 19.06.2025.
//

import Foundation

@MainActor
final class MyHistoryViewModel: ObservableObject {
    
    private let transactionService: TransactionService
    private let categoriesService: CategoriesService
    private let accountsService: BankAccountsService

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
        transactions.reduce(Decimal.zero) { result, transaction in
            if let decimalAmount = Decimal(string: transaction.amount) {
                return result + decimalAmount
            } else {
                return result
            }
        }
    }

    @Published var error: Error?

    @Published var sortOption: SortOption = .byDate
    
    
    init(
        direction: Direction,
        categoriesService: CategoriesService,
        accountsService: BankAccountsService
    ) {
        self.direction = direction
        self.categoriesService = categoriesService
        self.accountsService = accountsService
        
        self.transactionService = TransactionService(
            accountsService: accountsService,
            categoriesService: categoriesService 
        )
    }

    func loadData() async {
        isLoading = true
        do {
            categories = try await categoriesService.categories()
            let responses = try await transactionService.fetchTransactions(for: dateRange)

            let mappedTransactions = responses
                .map { $0.toTransaction() }
                .filter { transaction in
                    guard let category = categories.first(where: { $0.id == transaction.categoryId }) else {
                        return false
                    }
                    return category.direction == direction
                }

            transactions = mappedTransactions
        } catch {
            self.error = error
        }
        isLoading = false
    }

}


