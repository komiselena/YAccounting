//
//  BalanceScreen.swift
//  YAccounting
//
//  Created by Mac on 22.06.2025.
//

import SwiftUI

struct BalanceScreen: View {
    @StateObject var balanceViewModel: BalanceViewModel
    
    init() {
        self._balanceViewModel = StateObject(wrappedValue: BalanceViewModel())
    }
    
    var body: some View {
        NavigationStack{
            Group{
                switch balanceViewModel.balanceScreenState{
                case .edit:
                    BalanceEditView(balanceViewModel: balanceViewModel)
                case .view:
                    BalanceView(balanceViewModel: balanceViewModel)
                    
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if balanceViewModel.balanceScreenState == .view {
                            balanceViewModel.balanceScreenState = .edit
                        } else {
                            balanceViewModel.balanceScreenState = .view
                        }
                    } label: {
                        Text(balanceViewModel.balanceScreenState == .view ? "Редактировать" : "Сохранить")
                            .tint(.tint)
                    }
                    
                }
            }
            
            .navigationTitle("Мой счет")
        }
        .task{
            await balanceViewModel.loadBankAccountData()
        }
    }
    
    
}

#Preview {
    BalanceScreen()
}
