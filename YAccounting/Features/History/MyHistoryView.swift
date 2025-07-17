//
//  MyHistoryView.swift
//  YAccounting
//
//  Created by Mac on 17.06.2025.
//

import SwiftUI

struct MyHistoryView: View {
    @StateObject var viewModel: TransactionViewModel
    @StateObject private var historyViewModel: MyHistoryViewModel

    @State var direction: Direction
    
    private var sortedTransactions: [Transaction] {
        switch historyViewModel.sortOption {
        case .byDate:
            return historyViewModel.transactions.sorted(by: { $0.transactionDate > $1.transactionDate })
        case .byAmount:
            return historyViewModel.transactions.sorted(by: { $0.amount > $1.amount })
        }
    }
    
    init(direction: Direction, viewModel: TransactionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        _historyViewModel = StateObject(wrappedValue: MyHistoryViewModel(direction: direction))
        self.direction = direction
    }

    
    var body: some View {
        VStack{
            Form{
                Section{
                    DatePicker(
                        "Начало",
                        selection: $historyViewModel.startDate,
                        displayedComponents: .date
                    )
                    .accentColor(.tint)
                    .labelsHidden()
                    .datePickerStyle(.colored(backgroundColor: .operationImageBG))
                    .onChange(of: historyViewModel.startDate) { newValue in
                        if newValue > historyViewModel.endDate {
                            historyViewModel.endDate = newValue
                        }
                        Task { await historyViewModel.loadData() }
                    }
                    
                    DatePicker(
                        "Конец",
                        selection: $historyViewModel.endDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.colored(backgroundColor: .operationImageBG))
                    .onChange(of: historyViewModel.endDate) { newValue in
                        if newValue < historyViewModel.startDate {
                            historyViewModel.startDate = newValue
                        }
                        Task { await historyViewModel.loadData() }
                    }
                    
                    Picker("Сортировка", selection: $historyViewModel.sortOption) {
                        Text("По дате").tag(SortOption.byDate)
                        Text("По сумме").tag(SortOption.byAmount)
                    }
                    .pickerStyle(.menu)
                    .tint(.tint)
                    HStack{
                        Text("Сумма")
                        Spacer()
                        Text("\(historyViewModel.totalAmount) \(Currency.RUB.rawValue)")

                        
                    }

                }
                if historyViewModel.isLoading {
                    ProgressView()
                } else if let error = historyViewModel.error {
                    Text("Error: \(error.localizedDescription)")
                } else if historyViewModel.transactions.isEmpty {
                    Text("Нет операций за выбранный период")
                } else {
                    ForEach(sortedTransactions){ transaction in
                        let category = viewModel.categories.first { $0.id == transaction.categoryId }
                        Button {
                            viewModel.transaction = transaction
                            viewModel.transactionScreenMode = .edit
                            viewModel.selectedCategory = viewModel.categories.first(where: {$0.id == transaction.categoryId } ) ??  viewModel.categories.first
                            viewModel.comment = transaction.comment
                            viewModel.amountString = String(describing: transaction.amount)
                            viewModel.showTransactionView = true
                        } label: {
                            TransactionListRow(transaction: transaction, category: category)

                        }

                    }
                }

            }
        }
        .navigationTitle("Моя история")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AnalysisView(transactions: historyViewModel.transactions, categories: historyViewModel.categories)
                        .navigationTitle("Анализ")
                        .background(Color(.systemGroupedBackground))
                } label: {
                    Image(systemName: "document")

                }
            }
        }

        .refreshable {
            Task { await historyViewModel.loadData() }
        }

        .task {
            await historyViewModel.loadData()
        }

    }
    
}

#Preview {
    MyHistoryView(direction: .outcome, viewModel: TransactionViewModel(direction: .outcome))
}


