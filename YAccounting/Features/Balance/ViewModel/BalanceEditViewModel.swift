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
        guard let viewModel = balanceViewModel else { return }
        let currentBalance = Decimal(string: viewModel.bankAccount?.balance ?? "0") ?? 0
        let newBalance = Decimal(string: balanceText) ?? currentBalance
        
        if newBalance == currentBalance {
            editBalance = false
            return
        }

        await viewModel.updateBalance(newBalance)
        editBalance = false
        
    }
    
    private func filterBalanceInput(_ input: String) -> String {
        var filtered = input.filter { "0123456789.,".contains($0) }
        
        if let dotIndex = filtered.firstIndex(of: ".") {
            let afterDot = filtered[dotIndex...].replacingOccurrences(of: ".", with: "")
            filtered = String(filtered[..<dotIndex]) + "." + afterDot
        }
        
        if let dotIndex = filtered.firstIndex(of: ".") {
            let maxFractionDigits = 2
            let fractionalPart = filtered[filtered.index(dotIndex, offsetBy: 1)...]
            if fractionalPart.count > maxFractionDigits {
                filtered = String(filtered.prefix(upTo: filtered.index(dotIndex, offsetBy: 1 + maxFractionDigits)))
            }
        }
        
        return filtered
    }


}


