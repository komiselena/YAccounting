//
//  TransactionsListView.swift
//  YAccounting
//
//  Created by Mac on 14.06.2025.
//

import SwiftUI

struct TransactionsListView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject private var viewModel: TransactionViewModel
    @ObservedObject var networkMonitor = NetworkStatusMonitor.shared

    init(direction: Direction) {
        let categoriesService = CategoriesService()
        let accountsService = BankAccountsService()
        _viewModel = StateObject(wrappedValue: TransactionViewModel(
            direction: direction,
            categoriesService: categoriesService,
            accountsService: accountsService
        ))
    }

    private var sortedTransactions: [Transaction] {
        switch viewModel.sortOption {
        case .byDate:
            return viewModel.transactions.sorted(by: { $0.transactionDate > $1.transactionDate })
        case .byAmount:
            return viewModel.transactions.sorted(by: { $0.decimalAmount > $1.decimalAmount })
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                if !networkMonitor.isConnected {
                    OfflineBanner()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)

                }
                
                mainContent
            }
            .navigationTitle(viewModel.direction == .outcome ? "Расходы сегодня" : "Доходы сегодня")
            .background(Color(.systemGroupedBackground))

        }
        
        .refreshable {
            Task { await viewModel.loadData() }
        }
        
        .alert(item: $viewModel.alertState) { alertState in
            Alert(
                title: Text(alertState.title),
                message: Text(alertState.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .tint(Color("tintColor"))
        .fullScreenCover(isPresented: $viewModel.showTransactionView) {
            TransactionView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadData()
        }

    }

    private var mainContent: some View {
        Group {
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                ProgressView()
                    .font(.title3)
                    .tint(.tint)
            } else {
                List {
                    Section {
                        Picker("Сортировка", selection: $viewModel.sortOption) {
                            Text("По дате").tag(SortOption.byDate)
                            Text("По сумме").tag(SortOption.byAmount)
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Text("Всего")
                            Spacer()
                            Text("\(viewModel.totalAmount) \(Currency.RUB.rawValue)")
                        }
                        .font(.headline)
                    }
                    
                    Section("ОПЕРАЦИИ") {
                        ForEach(sortedTransactions) { transaction in
                            let category = viewModel.categories.first { $0.id == transaction.categoryId } ?? Category(id: 0, name: "Other", emoji: "❓", isIncome: false)
                            Button {
                                viewModel.transaction = transaction
                                viewModel.transactionScreenMode = .edit
                                viewModel.selectedCategory = category ?? viewModel.categories.first
                                viewModel.comment = transaction.comment
                                viewModel.amountString = transaction.amount
                                viewModel.date = transaction.transactionDate
                                viewModel.showTransactionView = true
                            } label: {
                                TransactionListRow(transaction: transaction, category: category)
                            }
                        }
                        .onDelete(perform: deleteTransaction)
                    }
                }
                .overlay(addButton, alignment: .bottomTrailing)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            MyHistoryView(direction: viewModel.direction)
                        } label: {
                            Image(systemName: "clock")
                        }
                    }
                }
                .navigationTitle(viewModel.direction == .outcome ? "Расходы сегодня" : "Доходы сегодня")
            }
        }
    }

    private var addButton: some View {
        Button {
            viewModel.prepareForNewTransaction()
        } label: {
            Image(systemName: "plus")
                .font(.title)
                .foregroundStyle(.white)
                .padding()
                .background(Circle().fill(.accent))
        }
        .padding(.bottom, 30)
        .padding(.trailing, 16)
    }

    private func deleteTransaction(at offsets: IndexSet) {
        offsets.forEach { index in
            Task {
                await viewModel.deleteTransaction()
            }
        }
    }
}

#Preview {
    TransactionsListView(direction: .outcome)
}
