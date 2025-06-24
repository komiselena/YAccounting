//
//  BalanceEditView.swift
//  YAccounting
//
//  Created by Mac on 22.06.2025.
//

import SwiftUI

struct BalanceEditView: View {
    @ObservedObject var balanceViewModel: BalanceViewModel
    @ObservedObject private var balanceEditvm: BalanceEditViewModel
    @State private var showPopup = false
    @FocusState private var isBalanceFieldFocused: Bool
    
    init(balanceViewModel: BalanceViewModel) {
        self.balanceViewModel = balanceViewModel
        self.balanceEditvm = BalanceEditViewModel(balanceViewModel: balanceViewModel)
    }

    var body: some View {
        VStack(spacing: 15) {
            balanceView()
            currencyView()
            Spacer()
        }
        .padding(.top)
        .overlay(
            FloatingSheet(isPresented: $showPopup) {
                currencyPopup
            }
        )
        .onChange(of: balanceViewModel.balanceScreenState) { newState in
            if newState == .view {
                Task {
                    await balanceEditvm.submitBalance()
                }
            }
        }
        .onChange(of: balanceEditvm.editBalance) { editing in
            if !editing && isBalanceFieldFocused {
                isBalanceFieldFocused = false
                Task { await balanceEditvm.submitBalance() }
            }
        }
        .swipeToDismiss($balanceEditvm.editBalance) {
            Task {
                await balanceEditvm.submitBalance()
            }
        }
    }
    
    private var currencyPopup: some View {
        VStack(spacing: 20) {
            Text("Валюта")
            Divider()
            Button("Российский рубль ₽") {
                balanceViewModel.currentCurrency = .RUB
                showPopup = false
            }
            Divider()
            Button("Американский доллар $") {
                balanceViewModel.currentCurrency = .USD
                showPopup = false
            }
            Divider()
            Button("Евро €") {
                balanceViewModel.currentCurrency = .EUR
                showPopup = false
            }
        }
    }
    
    private func balanceView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.white)
            HStack {
                Text("💰")
                    .padding(.trailing, 10)
                Text("Баланс")
                
                Spacer()
                
                if balanceEditvm.editBalance {
                    TextField("", text: $balanceEditvm.balanceText)
                        .keyboardType(.decimalPad)
                        .focused($isBalanceFieldFocused)
                        .multilineTextAlignment(.trailing)
                        .onSubmit {
                            Task { await balanceEditvm.submitBalance() }
                        }
                } else {
                    Text(balanceViewModel.bankAccount?.balance.formatted() ?? "0")
                        .foregroundStyle(.secondary)
                }
                
                Text(balanceViewModel.currentCurrency.rawValue)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .frame(height: 50)
        .onTapGesture {
            balanceEditvm.startEditingBalance()
        }
    }
    
    private func currencyView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.white)
            HStack {
                Text("Валюта")
                Spacer()
                Text(balanceViewModel.currentCurrency.rawValue)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .frame(height: 50)
        .onTapGesture {
            showPopup = true
        }
    }
}
#Preview {
    BalanceEditView(balanceViewModel: BalanceViewModel())
        .background(Color(.systemGroupedBackground))

}
