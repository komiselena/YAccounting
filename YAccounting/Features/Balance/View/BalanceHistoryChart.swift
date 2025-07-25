//
//  BalanceHistoryChart.swift
//  YAccounting
//
//  Created by Mac on 25.07.2025.
//


import SwiftUI
import Charts

struct BalanceHistoryChart: View {
    @ObservedObject var balanceViewModel: BalanceViewModel
    @State private var historyData: BankAccountHistory?
    @State private var selectedTimeRange: TimeRange = .days30
    @State private var selectedBalance: BalanceEntry?
    @State private var isEditing = false
    
    enum TimeRange: String, CaseIterable {
        case days30 = "30 дней"
        case months24 = "24 месяца"
    }
    
    private var dateRange30Days: [Date] {
        let calendar = Calendar.current
        let now = Date()
        let rangeEnd = calendar.startOfDay(for: now)
        let rangeStart = calendar.date(byAdding: .day, value: -29, to: rangeEnd)!
        
        return (0..<30).map { offset in
            calendar.date(byAdding: .day, value: offset, to: rangeStart)!
        }
    }
    
    private var dateRange24Months: [Date] {
        let calendar = Calendar.current
        let now = Date()
        let rangeEnd = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let rangeStart = calendar.date(byAdding: .month, value: -23, to: rangeEnd)!
        
        return (0..<24).map { offset in
            calendar.date(byAdding: .month, value: offset, to: rangeStart)!
        }
    }

    var body: some View {
        VStack {
            if !isEditing {
                Picker("Период", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if let historyData = historyData {
                    Chart {
                        ForEach(processedHistoryEntries(historyData), id: \.date) { entry in
                            BarMark(
                                x: .value("Дата", entry.date, unit: selectedTimeRange == .days30 ? .day : .month),
                                yStart: .value("Начало", 0),
                                yEnd: .value("Конец", abs(entry.balance) > 0 ? abs(entry.balance) : (selectedTimeRange == .days30 ? 100000 : 10000)),
                                width: .fixed(selectedTimeRange == .days30 ? 8 : 16)
                            )
                            .foregroundStyle(
                                entry.balance == 0 ? Color.gray.opacity(0.2) : (entry.balance > 0 ? Color.green : Color.red)
                            )
                            .cornerRadius(4)
                        }
                        
                        if let selectedBalance {
                            RuleMark(x: .value("Дата", selectedBalance.date))
                                .annotation(position: .top) {
                                    VStack {
                                        Text(selectedTimeRange == .days30 ?
                                             selectedBalance.date.formatted(date: .abbreviated, time: .omitted) :
                                             selectedBalance.date.formatted(.dateTime.year().month()))
                                        Text("\(formattedBalance(selectedBalance.balance))")
                                            .fontWeight(.bold)
                                    }
                                    .padding(8)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 4)
                                    .fixedSize()
                                }
                        }
                    }
                    .chartXScale(domain: selectedTimeRange == .days30 ?
                                dateRange30Days.first!...dateRange30Days.last! :
                                dateRange24Months.first!...dateRange24Months.last!)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedTimeRange == .days30 ? .day : .month,
                                                count: selectedTimeRange == .days30 ? 5 : 8)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    if selectedTimeRange == .days30 {
                                        Text(date.formatted(.dateTime.day().month()))
                                    } else {
                                        Text(date.formatted(.dateTime.year().month()))
                                            .font(.system(size: 10))
                                    }
                                }
                            }
                        }
                    }
                    .chartYAxis(.hidden)
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle().fill(.clear).contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let xPosition = min(max(value.location.x, 0), geometry.size.width)
                                            let date = proxy.value(atX: xPosition, as: Date.self) ?? Date()
                                            
                                            let calendar = Calendar.current
                                            if let foundEntry = processedHistoryEntries(historyData).first(where: {
                                                calendar.isDate($0.date, inSameDayAs: date)
                                            }) {
                                                self.selectedBalance = foundEntry
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedBalance = nil
                                        }
                                )
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    .animation(.easeInOut, value: selectedTimeRange)
                } else {
                    ProgressView()
                        .frame(height: 300)
                }
            }
        }
        .task {
            await loadHistoryData()
        }
        .onChange(of: balanceViewModel.bankAccount) { _ in
            Task {
                await loadHistoryData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .editModeChanged)) { notification in
            if let isEditing = notification.userInfo?["isEditing"] as? Bool {
                self.isEditing = isEditing
            }
        }
    }
    
    private func loadHistoryData() async {
        do {
            historyData = try await balanceViewModel.fetchHistory()
        } catch {
            print(error.localizedDescription)
            print("Error loading history data: \(error)")
        }
    }
    
    private func processedHistoryEntries(_ history: BankAccountHistory) -> [BalanceEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        if selectedTimeRange == .days30 {
            let rangeEnd = calendar.startOfDay(for: now)
            let rangeStart = calendar.date(byAdding: .day, value: -29, to: rangeEnd)!
            
            let dateRange = (0..<30).map { offset in
                calendar.date(byAdding: .day, value: offset, to: rangeStart)!
            }
            
            var historyDict: [Date: Decimal] = [:]
            dateRange.forEach { date in
                historyDict[date] = 0
            }
            
            for item in history.history {
                let d = calendar.startOfDay(for: item.changeTimestamp)
                if d >= rangeStart && d <= rangeEnd {
                    historyDict[d] = item.newState?.balance
                }
            }
            
            return dateRange.map { date in
                BalanceEntry(date: date, balance: historyDict[date] ?? 0)
            }
        } else {
            let rangeEnd = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let rangeStart = calendar.date(byAdding: .month, value: -23, to: rangeEnd)!
            
            let dateRange = (0..<24).map { offset in
                calendar.date(byAdding: .month, value: offset, to: rangeStart)!
            }
            
            var monthlyBalances: [Date: Decimal] = [:]
            
            dateRange.forEach { date in
                monthlyBalances[date] = 0
            }
            
            for item in history.history {
                let components = calendar.dateComponents([.year, .month], from: item.changeTimestamp)
                if let monthStart = calendar.date(from: components),
                   monthStart >= rangeStart && monthStart <= rangeEnd {
                    monthlyBalances[monthStart] = item.newState?.balance ?? monthlyBalances[monthStart] ?? 0
                }
            }
            
            var previousBalance: Decimal = 0
            return dateRange.map { date in
                let currentBalance = monthlyBalances[date] ?? previousBalance
                previousBalance = currentBalance
                return BalanceEntry(date: date, balance: currentBalance)
            }
        }
    }
    private func formattedBalance(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = Currency(rawValue: historyData?.currency ?? "RUB")?.symbol ?? "₽"
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

struct BalanceEntry: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Decimal
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
}

extension Currency {
    var symbol: String {
        switch self {
        case .RUB: return "₽"
        case .USD: return "$"
        case .EUR: return "€"
        }
    }
}

extension Notification.Name {
    static let editModeChanged = Notification.Name("editModeChanged")
}

#Preview{
    BalanceHistoryChart(balanceViewModel: BalanceViewModel(bankAccountService: BankAccountsService()))
}
