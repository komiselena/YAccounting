//
//  AnalysisView.swift
//  YAccounting
//
//  Created by Mac on 04.07.2025.
//

import SwiftUI

struct AnalysisView: UIViewControllerRepresentable {
    let transactions: [Transaction]
    let categories: [Category]

    func updateUIViewController(_ uiViewController: AnalysisViewController, context: Context) {
    }
    
    func makeUIViewController(context: Context) -> AnalysisViewController {
        return AnalysisViewController(transactions: transactions, categories: categories)
    }
}
