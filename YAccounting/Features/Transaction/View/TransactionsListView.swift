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
    
    init(direction: Direction) {
        _viewModel = StateObject(wrappedValue: TransactionViewModel(direction: direction))
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
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.tint)
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
                                Button {
                                    viewModel.transaction = transaction
                                    viewModel.transactionScreenMode = .edit
                                    print(transaction)
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
            }
            .overlay(
                Button{
                    viewModel.transaction = nil
                    viewModel.transactionScreenMode = .creation
                    viewModel.showTransactionView = true
                } label : {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            Circle()
                                .fill(.accent)
                        )
                }
                    .padding(.bottom, 30)
                    .padding(.trailing, 16)

                ,alignment: .bottomTrailing
            )
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MyHistoryView(direction: viewModel.direction, viewModel: viewModel)
                    } label: {
                        Image(systemName: "clock")
                    }
                    
                }
            })
            .navigationTitle(viewModel.direction == .outcome ? "Расходы сегодня" : "Доходы сегодня")
            
        }
        .alert(item: $viewModel.alertState) { alertState in
            Alert(
                title: Text(alertState.title),
                message: Text(alertState.message),
                dismissButton: .default(Text("OK"))
            )
        }

        .tint(Color("tintColor"))
        .task {
            await viewModel.loadData()
        }
        .fullScreenCover(isPresented: $viewModel.showTransactionView) {
            TransactionView(viewModel: viewModel)
        }
    }

}

#Preview {
    TransactionsListView(direction: .outcome)
}
