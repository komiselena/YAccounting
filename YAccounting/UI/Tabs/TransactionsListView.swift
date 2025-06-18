//
//  TransactionsListView.swift
//  YAccounting
//
//  Created by Mac on 14.06.2025.
//

import SwiftUI

struct TransactionsListView: View {
    @State var direction: Direction
    @StateObject var transactionService = TransactionService()
    @StateObject var categoriesService = CategoriesService()

    @State private var transactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var isLoading: Bool = false
    @State private var error: Error?
    
    private var totalAmount: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return start...end
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                if isLoading{
                    ProgressView()
                        .tint(.accent)
                    
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                }else if transactions.isEmpty {
                    Text("Нет транзакций за сегодня")
                }else{
                    List{
                        Section {
                            HStack{
                                Text("Всего")
                                    .foregroundStyle(.black)
                                    .font(.headline)
                                
                                Spacer()
                                Text("\(totalAmount) \(Currency.RUB.rawValue)")
                                    .foregroundStyle(.black)
                                    .font(.headline)
                                
                            }
                        }
                        
                        Section("ОПЕРАЦИИ") {
                            ForEach(transactions){ transaction in
                                let category = categories.first { $0.id == transaction.categoryId }
                                TransactionListRow(transaction: transaction, category: category)
                            }
                        }
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MyHistoryView(direction: direction, transactionService: transactionService)
                    } label: {
                        Image(systemName: "clock")
                    }

                }
            })
            .navigationTitle(direction == .outcome ? "Расходы сегодня" : "Доходы сегодня")

        }
        
        .tint(Color("tintColor"))
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
    TransactionsListView(direction: .income)
}
