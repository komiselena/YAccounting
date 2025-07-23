//
//  TransactionViewModel.swift
//  YAccounting
//
//  Created by Mac on 19.06.2025.
//

import Foundation
import Combine

@MainActor
final class TransactionViewModel: ObservableObject {
    private let transactionService: TransactionService
    private let categoriesService: CategoriesService
    private let accountsService: BankAccountsService
    private var cancellables = Set<AnyCancellable>()

    let direction: Direction
    var transaction: Transaction?

    @Published var transactionScreenMode: TransactionMode?
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var showTransactionView = false
    @Published var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var endDate = Date()
    @Published var error: Error?
    @Published var sortOption: SortOption = .byDate
    @Published var selectedCategory: Category?
    @Published var amountString: String = ""
    @Published var date: Date = Date.now
    @Published var comment: String?
    @Published var alertState: AlertState?

    @Published var isProcessingOperation: Bool = false

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
        return start...end
    }

    var totalAmount: Decimal {
        transactions.filter {
            Calendar.current.startOfDay(for: Date.now) <= $0.transactionDate && endDate >= $0.transactionDate }.reduce(Decimal.zero) { $0 + ($1.decimalAmount) }
    }

    private var isFormValid: Bool {
        selectedCategory != nil && !amountString.isEmpty && Decimal(string: amountString) != nil
    }
        
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }()
    

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


    init(
        direction: Direction,
        transaction: Transaction? = nil,
        categoriesService: CategoriesService,
        accountsService: BankAccountsService
    ) {
        self.direction = direction
        self.transaction = transaction
        self.categoriesService = categoriesService
        self.accountsService = accountsService
        self.transactionService = TransactionService(
            accountsService: accountsService,
            categoriesService: categoriesService
        )
        subscribeToUpdates()
    }

    private func subscribeToUpdates() {
        NotificationCenter.default.publisher(for: .transactionsUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let allCategories = try await categoriesService.categories()
            categories = allCategories.unique(by: \.id)
            
            let responses = try await transactionService.fetchTransactions(for: dateRange)
            let mappedTransactions = responses
                .map { $0.toTransaction() }
                .filter { transaction in
                    guard let category = categories.first(where: { $0.id == transaction.categoryId }) else { return false }
                    return category.direction == direction
                }
            self.transactions = mappedTransactions
        } catch {
            self.error = error
        }
    }

    func saveTransaction() {
        guard isFormValid else {
            showValidationAlert()
            return
        }
        Task {
            isProcessingOperation = true
            isLoading = true
            do {
                let transactionToSave = try createTransactionObject()
                if transactionScreenMode == .edit {
                    try await transactionService.editTransaction(transactionToSave)
                } else {
                    try await transactionService.createTransaction(transactionToSave)
                }
                
                if NetworkStatusMonitor.shared.isConnected {
                    resetForm()
                    showTransactionView = false
                } else {
                    alertState = AlertState(
                        type: .info,
                        title: "Сохранено в оффлайн",
                        message: "Транзакция будет синхронизирована при восстановлении соединения"
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.resetForm()
                        self.showTransactionView = false
                    }
                }
                
                await loadData()
            } catch {
                if !error.isNetworkError {
                    showErrorAlert(error)
                }
            }
            isLoading = false
            isProcessingOperation = false
        }
    }
    func createNewBankAccount() {
        Task {
            isLoading = true
            do {
                try await transactionService.createNewBankAccount()
            } catch {
                showErrorAlert(error)
            }
            isLoading = false
        }

    }
    


    private func createTransactionObject() throws -> Transaction {
        guard let selectedCategory = selectedCategory, let amount = Decimal(string: amountString) else {
            throw ValidationError.invalidData
        }
        let newId = transaction?.id ?? (transactions.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        return Transaction(
            id: newId,
            accountId: 1,
            categoryId: selectedCategory.id,
            amount: String(describing: amount),
            transactionDate: date,
            comment: comment,
            createdAt: transaction?.createdAt ?? Date(),
            updatedAt: Date()
        )
    }
    func deleteTransaction() async {
        guard let transaction = transaction else { return }
        isProcessingOperation = true
        isLoading = true
        do {
            try await transactionService.deleteTransaction(id: transaction.id)
            
            if !NetworkStatusMonitor.shared.isConnected {
                alertState = AlertState(
                    type: .info,
                    title: "Удалено локально",
                    message: "Транзакция будет удалена на сервере при восстановлении соединения"
                )
            }
            
            resetForm()
            await loadData()
        } catch {
            if !error.isNetworkError {
                self.error = error
                showErrorAlert(error)
            }
        }
        isLoading = false
        isProcessingOperation = false
    }
    private func resetForm() {
        transaction = nil
        selectedCategory = nil
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
        alertState = AlertState(
            type: .error,
            title: "Ошибка",
            message: error.localizedDescription
        )
    }

    func showValidationAlert() {
        alertState = AlertState(
            type: .validation,
            title: "Заполните все поля",
            message: "Пожалуйста, выберите категорию, укажите сумму и заполните все обязательные поля"
        )
    }

    func prepareForNewTransaction() {
        transaction = nil
        transactionScreenMode = .creation
        selectedCategory = nil
        comment = nil
        amountString = ""
        showTransactionView = true
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


