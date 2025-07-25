//
//  BarChart.swift
//  YAccounting
//
//  Created by Mac on 22.07.2025.
//

//import SwiftUI
//import Charts
//
//struct BarChart: View {
//    @StateObject var balanceViewModel: BalanceViewModel
//    @State private var historyData: BankAccountHistory?
//    @State private var selectedTimeRange: TimeRange = .days30
//    @State private var selectedBalance: BankAccountHistory?
//    @State private var isEditing = false
//
//    
//    var body: some View {
//        VStack {
//            if !isEditing {
//                Picker("Период", selection: $selectedTimeRange) {
//                    ForEach(TimeRange.allCases, id: \.self) { range in
//                        Text(range.rawValue).tag(range)
//                    }
//                }
//                .pickerStyle(SegmentedControlPickerStyle())
//                .padding()
//                
//                if let historyData = historyData {
//                    Chart {
//                        ForEach(filteredHistoryEntries(historyData.entries), id: \.date) { entry in
//                            BarMark(
//                                x: .value("Дата", entry.date, unit: selectedTimeRange == .days30 ? .day : .month),
//                                y: .value("Баланс", entry.balance.doubleValue)
//                            )
//                            .foregroundStyle(entry.balance >= 0 ? Color.green : Color.red)
//                            .opacity(selectedBalance?.date == entry.date ? 1 : 0.7)
//                        }
//                        
//                        if let selectedBalance {
//                            RuleMark(x: .value("Дата", selectedBalance.date))
//                                .annotation(position: .top) {
//                                    VStack {
//                                        Text("\(selectedBalance.date.formatted(date: .abbreviated, time: .omitted))")
//                                        Text("\(formattedBalance(selectedBalance.balance))")
//                                            .fontWeight(.bold)
//                                    }
//                                    .padding()
//                                    .background(Color(.systemBackground))
//                                    .cornerRadius(8)
//                                    .shadow(radius: 4)
//                                }
//                        }
//                    }
//                    .chartXAxis {
//                        AxisMarks(values: .stride(by: selectedTimeRange == .days30 ? .day : .month)) { value in
//                            AxisGridLine()
//                            AxisTick()
//                            AxisValueLabel(format: selectedTimeRange == .days30 ? .dateTime.day() : .dateTime.month(.abbreviated))
//                        }
//                    }
//                    .chartYAxis {
//                        AxisMarks(position: .leading)
//                    }
//                    .chartOverlay { proxy in
//                        GeometryReader { geometry in
//                            Rectangle().fill(.clear).contentShape(Rectangle())
//                                .gesture(
//                                    DragGesture()
//                                        .onChanged { value in
//                                            let xPosition = value.location.x - geometry[proxy.plotAreaFrame].origin.x
//                                            guard let date: Date = proxy.value(atX: xPosition) else { return }
//                                            
//                                            let calendar = Calendar.current
//                                            let foundEntry = filteredHistoryEntries(historyData.entries).first { entry in
//                                                if selectedTimeRange == .days30 {
//                                                    return calendar.isDate(entry.date, inSameDayAs: date)
//                                                } else {
//                                                    return calendar.isDate(entry.date, equalTo: date, toGranularity: .month)
//                                                }
//                                            }
//                                            selectedBalance = foundEntry
//                                        }
//                                        .onEnded { _ in
//                                            selectedBalance = nil
//                                        }
//                                )
//                        }
//                    }
//                    .frame(height: 300)
//                    .padding()
//                    .animation(.easeInOut, value: selectedTimeRange)
//                } else {
//                    ProgressView()
//                        .frame(height: 300)
//                }
//            }
//        }
//        .task {
//            await loadHistoryData()
//        }
//        .onChange(of: balanceViewModel.bankAccount) { _ in
//            Task {
//                await loadHistoryData()
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(for: .editModeChanged)) { notification in
//            if let isEditing = notification.userInfo?["isEditing"] as? Bool {
//                self.isEditing = isEditing
//            }
//        }
//    }
//    
//    private func loadHistoryData() async {
//        do {
//            historyData = try await balanceViewModel.fetchHistory()
//        } catch {
//            print("Error loading history data: \(error)")
//        }
//    }
//    
//    private func filteredHistoryEntries(_ entries: [BankAccountHistory]) -> [BankAccountHistory] {
//        let calendar = Calendar.current
//        let now = Date()
//        let rangeEnd = now
//        let rangeStart: Date
//        
//        if selectedTimeRange == .days30 {
//            rangeStart = calendar.date(byAdding: .day, value: -30, to: now)!
//        } else {
//            rangeStart = calendar.date(byAdding: .month, value: -24, to: now)!
//        }
//        
//        return entries.filter { entry in
//            rangeStart...rangeEnd ~= entry.date
//        }
//    }
//    
//    private func formattedBalance(_ value: Decimal) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.currencySymbol = balanceViewModel.currentCurrency.symbol
//        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
//    }
//}
//
//#Preview {
//    BarChart(balanceViewModel: BalanceViewModel(bankAccountService: BankAccountsService()))
//}
//
//
//enum TimeRange: String, CaseIterable {
//    case days30 = "30 дней"
//    case months24 = "24 месяца"
//}
//extension Decimal {
//    var doubleValue: Double {
//        return NSDecimalNumber(decimal: self).doubleValue
//    }
//}
//
//extension Currency {
//    var symbol: String {
//        switch self {
//        case .RUB: "₽"
//        case .USD: "$"
//        case .EUR: "€"
//        }
//    }
//}
