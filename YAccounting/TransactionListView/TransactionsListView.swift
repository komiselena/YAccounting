//
//  TransactionsListView.swift
//  YAccounting
//
//  Created by Mac on 14.06.2025.
//

import SwiftUI

struct TransactionsListView: View {
    
    @StateObject private var viewModel: TransactionsListViewModel

    init(direction: Direction) {
        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(direction: direction))
    }

    private var sortedTransactions: [Transaction] {
        switch viewModel.sortOption {
        case .byDate:
            return viewModel.transactions.sorted(by: { $0.transactionDate > $1.transactionDate })
        case .byAmount:
            return viewModel.transactions.sorted(by: { $0.amount > $1.amount })
        }
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                if viewModel.isLoading && sortedTransactions.isEmpty {
                    ProgressView()
                        .tint(.tint)
                    
                } else if let error = viewModel.error {
                    Text("Error: \(error.localizedDescription)")
                }else{
                    List{
                        Section {
                            Picker("Сортировка", selection: $viewModel.sortOption) {
                                Text("По дате").tag(SortOption.byDate)
                                Text("По сумме").tag(SortOption.byAmount)
                            }
                            .pickerStyle(.menu)
                            
                            HStack{
                                Text("Всего")
                                    .foregroundStyle(.black)
                                    .font(.headline)
                                
                                Spacer()
                                Text("\(viewModel.totalAmount) \(Currency.RUB.rawValue)")
                                    .foregroundStyle(.black)
                                    .font(.headline)
                                
                            }
                        }
                        
                        Section("ОПЕРАЦИИ") {
                            ForEach(sortedTransactions){ transaction in
                                let category = viewModel.categories.first { $0.id == transaction.categoryId }
                                NavigationLink {
                                    EmptyView()
                                } label: {
                                    TransactionListRow(transaction: transaction, category: category)

                                }

                            }
                        }
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MyHistoryView(direction: viewModel.direction)
                    } label: {
                        Image(systemName: "clock")
                    }
                    
                }
            })
            .navigationTitle(viewModel.direction == .outcome ? "Расходы сегодня" : "Доходы сегодня")
            
        }
        
        .tint(Color("tintColor"))
        .task {
            await viewModel.loadData()
        }
    }

}

#Preview {
    TransactionsListView(direction: .outcome)
}
