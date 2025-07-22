//
//  BalanceEditViewModel.swift
//  YAccounting
//
//  Created by Mac on 24.06.2025.
//

import SwiftUI

@MainActor
final class BalanceEditViewModel: ObservableObject {
    private weak var balanceViewModel: BalanceViewModel?
    @Published var editBalance = false
    @Published var balanceText: String = ""
    @Published var isUpdating = false
    @Published var error: Error?
    
    init(balanceViewModel: BalanceViewModel) {
        self.balanceViewModel = balanceViewModel
    }
    
    func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            balanceText = filterBalanceInput(clipboardContent)
        }
    }
    
    func startEditingBalance() {
        balanceText = balanceViewModel?.bankAccount?.balance ?? "0"
        editBalance = true
    }
    
    func submitBalance() async {
        isUpdating = true
        defer { isUpdating = false }
        
        guard let viewModel = balanceViewModel else { return }
        
        // Используем правильный формат для Decimal
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        
        let currentBalance = Decimal(string: viewModel.bankAccount?.balance ?? "0", locale: Locale(identifier: "en_US")) ?? 0
        let newBalance = Decimal(string: balanceText, locale: Locale(identifier: "en_US")) ?? currentBalance
        
        if newBalance == currentBalance {
            editBalance = false
            return
        }

        do {
            await viewModel.updateBalance(newBalance)
            editBalance = false
        } catch {
            self.error = error
        }
    }
    
    private func filterBalanceInput(_ input: String) -> String {
        // Заменяем запятые на точки и оставляем только цифры и точку
        var filtered = input.replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        
        // Удаляем лишние точки
        if let firstDotIndex = filtered.firstIndex(of: ".") {
            let beforeDot = filtered[..<firstDotIndex]
            let afterDot = filtered[filtered.index(after: firstDotIndex)...].filter { $0 != "." }
            filtered = String(beforeDot) + "." + afterDot
        }
        
        // Ограничиваем дробную часть до 2 знаков
        if let dotIndex = filtered.firstIndex(of: ".") {
            let fractionalPart = filtered[filtered.index(after: dotIndex)...]
            if fractionalPart.count > 2 {
                filtered = String(filtered.prefix(upTo: filtered.index(dotIndex, offsetBy: 3)))
            }
        }
        
        return filtered
    }
}
