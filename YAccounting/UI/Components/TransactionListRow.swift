//
//  TransactionListRow.swift
//  YAccounting
//
//  Created by Mac on 16.06.2025.
//

import SwiftUI

struct TransactionListRow: View {
    @State var transaction: Transaction
    @State var category: Category?
    
    var body: some View {
        
        HStack{
            ZStack{
                Circle()
                    .fill(.operationImageBG)
                    .frame(width: 40, height: 40)
                Text("\(category?.emoji ?? "❓")")
                
            }

            VStack(alignment: .leading) {
                Text(category?.name ?? "Other")
                    .foregroundStyle(.black)
                if ((transaction.comment?.isEmpty) == nil) {
                    Text(transaction.comment ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()

            Text("\(transaction.amount) \(Currency.RUB.rawValue)")
            
        }
        
    }
    
}

#Preview {
    TransactionListRow(transaction: Transaction(id: 1, accountId: 1, categoryId: 1, amount: 1111, transactionDate: Date.now, comment: "", createdAt: Date.now, updatedAt: Date.now), category: Category(id: 1, name: "", emoji: "✅", isIncome: true))
}
