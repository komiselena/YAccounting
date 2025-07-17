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
    
    @Published var showErrorAlert = false
    @Published var errorMessage: String?
    
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
    @Published var comment: String?
    @Published var showDeleteConfirmation = false
    
    private var loadDataTask: Task<Void, Never>?

    private var isFormValid: Bool {
        selectedCategory != nil && !amountString.isEmpty && Decimal(string: amountString) != nil
    }
        
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    @Published var alertState: AlertState?
    

    func validateAmount(_ input: String) -> String {
        let decimalSeparator = numberFormatter.decimalSeparator ?? "."
        let allowedCharacters = CharacterSet(charactersIn: "0123456789" + decimalSeparator)
        let filtered = input.components(separatedBy: allowedCharacters.inverted).joined()
        
        let components = filtered.components(separatedBy: decimalSeparator)
        switch components.count {
        case 1 where components[0].count > 10:
            return String(components[0].prefix(10))
        case 2 where components[1].count > 2:
            return components[0] + decimalSeparator + String(components[1].prefix(2))
        default:
            return filtered
        }
    }


    init(direction: Direction, transaction: Transaction? = nil) {
        self.direction = direction
        self.transaction = transaction
    }
    
    deinit {
        loadDataTask?.cancel()
    }


    func loadData() async {
        loadDataTask?.cancel()

        isLoading = true
        defer { isLoading = false }

        loadDataTask = Task {
            do {
                categories = try await categoriesService.categories()
                let responses = try await transactionService.fetchTransactions(for: dateRange)
                
                if !Task.isCancelled {
                    let mappedTransactions = responses
                        .map { $0.toTransaction() }
                        .filter { transaction in
                            guard let category = categories.first(where: { $0.id == transaction.categoryId }) else {
                                return false
                            }
                            return category.direction == direction
                        }
                    
                    transactions = mappedTransactions
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                }
            }
            isLoading = false
        }
    }
    
    func saveTransaction() {
        guard isFormValid else {
            showValidationAlert()
            return
        }
        
        Task {
            isLoading = true
            do {
                let transaction = try createTransactionObject()
                
                if transactionScreenMode == .edit {
                    guard let origiTransaction = self.transaction else {
                        throw ValidationError.invalidData
                    }
                    
                    let updatedTransaction = Transaction(
                        id: origiTransaction.id,
                        accountId: transaction.accountId,
                        categoryId: transaction.categoryId,
                        amount: transaction.amount,
                        transactionDate: transaction.transactionDate,
                        comment: transaction.comment,
                        createdAt: origiTransaction.createdAt,
                        updatedAt: origiTransaction.updatedAt
                    )
                    
                    try await transactionService.editTransaction(updatedTransaction)
                } else {
                    try await transactionService.createTransaction(transaction)
                }
                
                await loadData()
                resetForm()
            } catch {
                showErrorAlert(error)
            }
            isLoading = false
        }
    }

    private func createTransactionObject() throws -> Transaction {
        guard let selectedCategory = selectedCategory,
              let amount = Decimal(string: amountString) else {
            throw ValidationError.invalidData
        }
        
        return Transaction(
            id: transaction?.id ?? 1,
            accountId: 1,
            categoryId: selectedCategory.id,
            amount: amount,
            transactionDate: date,
            comment: comment,
            createdAt: transaction?.createdAt,
            updatedAt: transaction?.updatedAt
        )
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
        resetForm()
        isLoading = false
    }
    
    private func resetForm() {
        amountString = ""
        comment = ""
        date = Date.now
        showTransactionView = false
    }

    func showDeleteAlert() {
        alertState = AlertState(
            type: .deleteConfirmation,
            title: "Удалить операцию?",
            message: "Вы уверены, что хотите удалить этот \(direction == .income ? "доход" : "расход")?"
        )
    }
    
    private func showErrorAlert(_ error: Error) {
        let message: String
        
        if let networkError = error as? NetworkError {
            message = networkError.localizedDescription
        } else {
            message = "Пожалуйста, попробуйте снова"
        }
        
        alertState = AlertState(
            type: .error,
            title: "Ошибка",
            message: message
        )
    }
    
    func showValidationAlert() {
        alertState = AlertState(
            type: .validation,
            title: "Заполните все поля",
            message: "Пожалуйста, выберите категорию, укажите сумму и заполните все обязательные поля"
        )
    }


}


enum ValidationError: LocalizedError {
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidData: return "Invalid transaction data"
        }
    }
}


