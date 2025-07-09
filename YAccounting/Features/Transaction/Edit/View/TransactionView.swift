//
//  TransactionView.swift
//  YAccounting
//
//  Created by Mac on 09.07.2025.
//

import SwiftUI

struct TransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    @State private var currentPhase: TransactionDetails = .edit
    @StateObject var viewModel: TransactionViewModel

    @State private var category: Category?
    @State private var amount: Decimal = 0.0
    @State private var date: Date = Date.now
    @State private var time: Date = Date.now
    @State private var comment: String = ""

    private var isFormValid: Bool {
        category != nil && !amountString.isEmpty && Decimal(string: amountString) != nil
    }
    
    private var decimalSeparator: String {
        locale.decimalSeparator ?? "."
    }

    var body: some View {
        VStack{
            Form {
                Section {
                    Picker("Статья", selection: $category) {
                        Text("Не выбрано").tag(nil as Category?)
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text("\(category.emoji) \(category.name)").tag(category as Category?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    HStack {
                        Text("Сумма")
                        Spacer()
                        TextField("0", text: $amountString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .onChange(of: amountString) { newValue in
                                // Validate input - only numbers and one decimal separator
                                let filtered = newValue.filter { char in
                                    char.isNumber || String(char) == decimalSeparator
                                }
                                
                                // Allow only one decimal separator
                                let components = filtered.components(separatedBy: decimalSeparator)
                                if components.count > 2 {
                                    amountString = components[0] + decimalSeparator + components[1]
                                } else {
                                    amountString = filtered
                                }
                            }
                    }
                    
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                        .accentColor(.tint)
                        .datePickerStyle(.compact)
                        .disabled(date > Date.now) // Disable future dates
                    
                    DatePicker("Время", selection: $date, displayedComponents: .hourAndMinute)
                        .accentColor(.tint)
                        .datePickerStyle(.compact)
                    
                    ZStack(alignment: .leading) {
                        if comment.isEmpty {
                            Text("Комментарий")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $comment)
                            .foregroundColor(.primary)
                    }
                }
            }

            .navigationTitle(viewModel.direction == .income ? "Мои Доходы" : "Мои Расходы")
            
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.mode == .edit ? "Сохранить" : "Создать") {
                    if isFormValid {
                        saveTransaction()
                    } else {
                        showValidationAlert = true
                    }
                }
            }
            
            if viewModel.mode == .edit {
                ToolbarItem(placement: .bottomBar) {
                    Button("Удалить", role: .destructive) {
                        viewModel.deleteTransaction()
                        dismiss()
                    }
                }
            }
        }
        .alert("Заполните все поля", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Пожалуйста, выберите категорию, укажите сумму и заполните все обязательные поля")
        }
        .onAppear {
            if viewModel.mode == .edit, let transaction = viewModel.transaction {
                category = viewModel.categories.first(where: { $0.id == transaction.categoryId })
                amountString = transaction.amount.formatted()
                date = transaction.transactionDate
                comment = transaction.comment ?? ""
            }
        }


    }
}

#Preview {
    TransactionView(viewModel: TransactionViewModel(direction: .income))
}


enum TransactionDetails {
    case creation
    case edit
}
