//
//  MyHistoryView.swift
//  YAccounting
//
//  Created by Mac on 17.06.2025.
//

import SwiftUI

struct MyHistoryView: View {
    @State var direction: Direction
    @StateObject var transactionService: TransactionService
    @StateObject var categoriesService = CategoriesService()

    @State var transactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var isLoading = false
    @State private var error: Error?

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate = Date()
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
        return start...end
    }

    private var totalAmount: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }

    @State private var sortOption: SortOption = .byDate
    
    private var sortedTransactions: [Transaction] {
        switch sortOption {
        case .byDate:
            return transactions.sorted(by: { $0.transactionDate > $1.transactionDate })
        case .byAmount:
            return transactions.sorted(by: { $0.amount > $1.amount })
        }
    }

    
    var body: some View {
        VStack{
            Form{
                Section{
                    DatePicker(
                        "Начало",
                        selection: $startDate,
                        displayedComponents: [.date]
                    )
                    .onChange(of: startDate) { newValue in
                        if newValue > endDate {
                            endDate = newValue
                        }
                        Task { await loadData() }
                    }
                    
                    DatePicker(
                        "Конец",
                        selection: $endDate,
                        displayedComponents: [.date]
                    )

                    .onChange(of: endDate) { newValue in
                        if newValue < startDate {
                            startDate = newValue
                        }
                        Task { await loadData() }
                    }
                    
                    Picker("Сортировка", selection: $sortOption) {
                        Text("По дате").tag(SortOption.byDate)
                        Text("По сумме").tag(SortOption.byAmount)
                    }
                    .pickerStyle(.menu)
                    .tint(.tint)
                    HStack{
                        Text("Сумма")
                        Spacer()
                        Text("\(totalAmount) \(Currency.RUB.rawValue)")

                        
                    }

                }
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                } else if transactions.isEmpty {
                    Text("Нет операций за выбранный период")
                } else {
                    ForEach(sortedTransactions) { transaction in
                        let category = categories.first { $0.id == transaction.categoryId }
                        TransactionListRow(transaction: transaction, category: category)
                    }
                }

            }
        }
        .navigationTitle("Моя история")
        .refreshable {
            Task { await loadData() }
        }

        .task {
             await loadData()
        }

    }
    
    private func loadData() async {
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

#Preview {
    MyHistoryView(direction: .outcome, transactionService: TransactionService(), transactions: [])
}


