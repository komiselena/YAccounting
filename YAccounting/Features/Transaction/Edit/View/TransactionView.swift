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

    @StateObject var viewModel: TransactionViewModel
    @StateObject var balanceViewModel: BalanceViewModel

    private var decimalSeparator: String {
        locale.decimalSeparator ?? "."
    }

    
    init(viewModel: TransactionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._balanceViewModel = StateObject(wrappedValue: BalanceViewModel())
    }
    
    var body: some View {
        NavigationStack{
            if viewModel.isLoading {
                ProgressView()
            } else {
                
                Form {
                    Section {
                        Picker("Статья", selection: $viewModel.selectedCategory) {
                            ForEach(viewModel.categories.filter { $0.direction == viewModel.direction }, id: \.self) { category in
                                Text("\(category.emoji) \(category.name)").tag(category as Category?)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Сумма")
                            Spacer()
                            TextField("0", text: $viewModel.amountString)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .onChange(of: viewModel.amountString) { newValue in
                                    let filtered = newValue.filter { char in
                                        char.isNumber || String(char) == decimalSeparator
                                    }
                                    
                                    let components = filtered.components(separatedBy: decimalSeparator)
                                    if components.count > 2 {
                                        viewModel.amountString = components[0] + decimalSeparator + components[1]
                                    } else {
                                        viewModel.amountString = filtered
                                    }
                                }
                            Text("\(balanceViewModel.currentCurrency.rawValue)")
                                .foregroundStyle(.secondary)

                        }
                        
                        DatePicker("Дата", selection: $viewModel.date, in: ...Date.now, displayedComponents: .date)
                        //                        .accentColor(.accentColor)
                        //                        .labelsHidden()
                        //                        .datePickerStyle(.colored(backgroundColor: .operationImageBG))
                        
                        DatePicker("Время", selection: $viewModel.date, displayedComponents: .hourAndMinute)
                        //                        .accentColor(.accentColor)
                        //                        .labelsHidden()
                        //                        .datePickerStyle(.colored(backgroundColor: .operationImageBG))
                        
                        ZStack(alignment: .leading) {
                            if viewModel.comment.isEmpty {
                                Text("Комментарий")
                                    .foregroundColor(.secondary)
                            }
                            TextField("", text: $viewModel.comment)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if viewModel.transactionScreenMode == .edit {
                        Section {
                            Button(role: .destructive) {
                                viewModel.showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Удалить")
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .navigationTitle(viewModel.direction == .income ? "Мои Доходы" : "Мои Расходы")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            dismiss()
                            viewModel.amountString = ""
                            viewModel.comment = ""
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button(viewModel.transactionScreenMode == .edit ? "Сохранить" : "Создать") {
                            viewModel.saveTransaction()
                        }
                    }
                }
                .tint(.tint)
            }
        }
        .alert("Заполните все поля", isPresented: $viewModel.showValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Пожалуйста, выберите категорию, укажите сумму и заполните все обязательные поля")
        }
        .alert("Удалить операцию?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Удалить", role: .destructive) {
                Task {
                    await viewModel.deleteTransaction()
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .alert("Ошибка", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Неизвестная ошибка")
        }
        .task {
            await viewModel.loadInitialData()
            await balanceViewModel.loadBankAccountData()
        }

    }
    
}

#Preview {
    TransactionView(
        viewModel: TransactionViewModel(direction: .income)
        
    )
}
