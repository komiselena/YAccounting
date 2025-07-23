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
        self._balanceViewModel = StateObject(wrappedValue: BalanceViewModel(bankAccountService: BankAccountsService.shared))
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
                                    viewModel.amountString = viewModel.validateAmount(newValue)
                                }
                            Text("\(balanceViewModel.currentCurrency.rawValue)")
                                .foregroundStyle(.secondary)
                        }

                        DatePicker("Дата", selection: $viewModel.date, in: ...Date.now, displayedComponents: .date)
                                                .accentColor(.accentColor)
//                                                .labelsHidden()
//                                                .datePickerStyle(.colored(backgroundColor: .operationImageBG))
                        
                        DatePicker("Время", selection: $viewModel.date, displayedComponents: .hourAndMinute)
                                                .accentColor(.accentColor)
//                                                .labelsHidden()
//                                                .datePickerStyle(.colored(backgroundColor: .operationImageBG))
                        
                        ZStack(alignment: .leading) {
                            if (viewModel.comment ?? "").isEmpty {
                                Text("Комментарий")
                                    .foregroundColor(.secondary)
                            }
                            TextField("", text: Binding(
                                get: { viewModel.comment ?? "" },
                                set: { viewModel.comment = $0.isEmpty ? nil : $0 }
                            ))
                            .foregroundColor(.primary)
                        }
                    }
                    
                    if viewModel.transactionScreenMode == .edit {
                        Section {
                            Button(role: .destructive) {
                                viewModel.showDeleteAlert()
                            } label: {
                                HStack {
                                    Text("Удалить \(viewModel.direction == .income ? "доход" : "расход")")
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
        .alert(item: $viewModel.alertState) { alertState in
            switch alertState.type {
            case .validation:
                return Alert(
                    title: Text(alertState.title),
                    message: Text(alertState.message),
                    dismissButton: .default(Text("OK"))
                )
            case .deleteConfirmation:
                return Alert(
                    title: Text(alertState.title),
                    message: Text(alertState.message),
                    primaryButton: .destructive(Text("Удалить")) {
                        Task {
                            await viewModel.deleteTransaction()
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .error:
                return Alert(
                    title: Text(alertState.title),
                    message: Text(alertState.message),
                    dismissButton: .default(Text("OK")) {
                        viewModel.alertState = nil
                    }
                )
            case .info:
                return Alert(
                    title: Text(alertState.title),
                    message: Text(alertState.message),
                    dismissButton: .default(Text("OK")) {
                        viewModel.alertState = nil
                    }
                )

            }
        }
//        .task {
//            await balanceViewModel.loadBankAccountData()
//        }
    }
}
