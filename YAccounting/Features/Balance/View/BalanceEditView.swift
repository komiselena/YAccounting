//
//  BalanceEditView.swift
//  YAccounting
//
//  Created by Mac on 22.06.2025.
//

import SwiftUI

struct BalanceEditView: View {
    @ObservedObject var balanceViewModel: BalanceViewModel
    // ИСПРАВЛЕНО: Изменено на @StateObject для правильного управления состоянием
    @StateObject private var balanceEditvm: BalanceEditViewModel
    @State private var showPopup = false
    @FocusState private var isBalanceFieldFocused: Bool
    
    init(balanceViewModel: BalanceViewModel) {
        self.balanceViewModel = balanceViewModel
        // ИСПРАВЛЕНО: Правильная инициализация @StateObject
        self._balanceEditvm = StateObject(wrappedValue: BalanceEditViewModel(balanceViewModel: balanceViewModel))
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
        // ДОБАВЛЕНО: Инициализация при появлении представления
        .onAppear {
            if !balanceEditvm.editBalance {
                balanceEditvm.startEditingBalance()
            }
        }
    }
    
    private var currencyPopup: some View {
        VStack(spacing: 20) {
            Text("Валюта")
            Divider()
            
            currencyButtonView(currency: "Российский рубль ₽")

            Divider()
            currencyButtonView(currency: "Американский доллар $")
            
            Divider()
            currencyButtonView(currency: "Евро €")
        }
    }
    
    private func currencyButtonView(currency: String) -> some View {
        Button {
            switch currency{
            case "Российский рубль ₽":
                balanceViewModel.currentCurrency = .RUB
                showPopup = false
                Task {
                    await balanceViewModel.updateCurrency(Currency.RUB.rawValue)
                }

            case "Американский доллар $":
                balanceViewModel.currentCurrency = .USD
                showPopup = false
                Task {
                    await balanceViewModel.updateCurrency(Currency.USD.rawValue)
                }

            case "Евро €":
                balanceViewModel.currentCurrency = .EUR
                showPopup = false
                Task {
                    await balanceViewModel.updateCurrency(Currency.EUR.rawValue)
                }

            default:
                balanceViewModel.currentCurrency = .RUB
                showPopup = false
                Task {
                    await balanceViewModel.updateCurrency(Currency.RUB.rawValue)
                }

            }

        } label: {
            Text(currency)
                .padding(.horizontal)
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
                    // ИСПРАВЛЕНО: Используем форматтер для отображения Decimal
                    Text("\(formatBalance(balanceViewModel.bankAccount?.balance ?? 0))")
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
            isBalanceFieldFocused = true
        }
    }
    
    // ДОБАВЛЕНО: Метод форматирования баланса
    private func formatBalance(_ balance: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: balance)) ?? "0"
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

