//
//  BarChart.swift
//  YAccounting
//
//  Created by Mac on 22.07.2025.
//

import SwiftUI
import Charts

struct BarChart: View {
    @StateObject var balanceViewModel: BalanceViewModel
    
//    var data = [
//        
//    ]
    
    var body: some View {
//        Chart(data) {
//            BarMark(
//                x: .value("Time", $0.date),
//                y: .value("Amount", $0.amount)
//            )
//        }
    }
}

#Preview {
    BarChart(balanceViewModel: BalanceViewModel())
}
