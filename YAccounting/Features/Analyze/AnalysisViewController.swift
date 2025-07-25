//
//  AnalysisViewController.swift
//  YAccounting
//
//  Created by Mac on 08.07.2025.
//

import UIKit
import PieChart

class AnalysisViewController: UIViewController {
    private var startDate: Date = Date()
    private var endDate: Date = Date()

    private let allTransactions: [Transaction]
    private let categories: [Category]
    private var transactions: [Transaction] = []
    private var sortedBy: SortOption = .byDate

    init(transactions: [Transaction], categories: [Category]) {
        self.allTransactions = transactions
        self.categories = categories
        super.init(nibName: nil, bundle: nil)

        if let minDate = transactions.map({ $0.transactionDate }).min() {
            self.startDate = minDate
        }
        if let maxDate = transactions.map({ $0.transactionDate }).max() {
            self.endDate = maxDate
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var pieChartView: PieChartView = {
        let view = PieChartView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var chartContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    private lazy var backButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        button.tintColor = .systemBlue
        return button
    }()
    
    private lazy var sortButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Сортировка", style: .plain, target: self, action: #selector(sortButtonTapped))
        return button
    }()
    
    private lazy var sortValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var periodView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var startLabel: UILabel = {
        let label = UILabel()
        label.text = "Период: начало"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var startDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(formatDate(Date()), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(selectStartDate), for: .touchUpInside)
        return button
    }()
    
    private lazy var endLabel: UILabel = {
        let label = UILabel()
        label.text = "Период: конец"
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var endDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(formatDate(Date()), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(selectEndDate), for: .touchUpInside)
        return button
    }()
    
    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 ₽"
        label.font = .boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var operationsLabel: UILabel = {
        let label = UILabel()
        label.text = "ОПЕРАЦИИ"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var operationsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: "TransactionCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        return tableView
    }()
    
    private var tableHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupConstraints()
        filterAndReload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Анализ"
    }
    
    private func setupNavigationBar() {
        title = "Анализ"
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = sortButton
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        startDateButton.setTitle(formatDate(startDate), for: .normal)
        endDateButton.setTitle(formatDate(endDate), for: .normal)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(periodView)
        contentView.addSubview(chartContainer)
        chartContainer.addSubview(pieChartView)
        contentView.addSubview(operationsLabel)
        contentView.addSubview(operationsContainer)
        operationsContainer.addSubview(tableView)
        
        chartContainer.backgroundColor = .clear

        
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.distribution = .fill
        verticalStack.alignment = .fill
        verticalStack.spacing = 12
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        let sortTitle = UILabel()
        sortTitle.text = "Сортировка"
        sortTitle.font = .systemFont(ofSize: 16)
        
        sortValueLabel.text = sortedBy == .byDate ? "По дате" : "По сумме"
        
        let sortRow = makeRow(titleLabel: sortTitle, valueView: sortValueLabel, isLast: false)
        let sortTap = UITapGestureRecognizer(target: self, action: #selector(showSortOptions))
        sortRow.addGestureRecognizer(sortTap)
        sortRow.isUserInteractionEnabled = true

        let startRow = makeRow(titleLabel: startLabel, valueView: startDateButton, isLast: false)
        let endRow = makeRow(titleLabel: endLabel, valueView: endDateButton, isLast: false)
        let sumTitle = UILabel()
        sumTitle.text = "Сумма"
        sumTitle.font = .systemFont(ofSize: 16)
        let sumRow = makeRow(titleLabel: sumTitle, valueView: amountLabel, isLast: true)
        
        chartContainer.backgroundColor = .clear
        pieChartView.backgroundColor = .clear

        [startRow, endRow, sortRow, sumRow].forEach { verticalStack.addArrangedSubview($0) }
        
        periodView.addSubview(verticalStack)
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: periodView.topAnchor, constant: 16),
            verticalStack.leadingAnchor.constraint(equalTo: periodView.leadingAnchor, constant: 16),
            verticalStack.trailingAnchor.constraint(equalTo: periodView.trailingAnchor, constant: -16),
            verticalStack.bottomAnchor.constraint(equalTo: periodView.bottomAnchor, constant: -16),
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            periodView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            periodView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            periodView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            chartContainer.topAnchor.constraint(equalTo: periodView.bottomAnchor, constant: 16),
            chartContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartContainer.heightAnchor.constraint(equalToConstant: 300),

            pieChartView.topAnchor.constraint(equalTo: chartContainer.topAnchor, constant: 8),
            pieChartView.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor, constant: 8),
            pieChartView.trailingAnchor.constraint(equalTo: chartContainer.trailingAnchor, constant: -8),
            pieChartView.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: -8),
            
            operationsLabel.topAnchor.constraint(equalTo: chartContainer.bottomAnchor, constant: 16),
            operationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            operationsLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            operationsContainer.topAnchor.constraint(equalTo: operationsLabel.bottomAnchor, constant: 8),
            operationsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            operationsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            operationsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: operationsContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: operationsContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: operationsContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: operationsContainer.bottomAnchor)
        ])
        
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
    }

    private func filterAndReload() {
        transactions = allTransactions.filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
        updateTotalAmount()
        updatePieChartData()
        sortTransactions()
        
        DispatchQueue.main.async {
            self.tableView.layoutIfNeeded()
            self.tableHeightConstraint?.constant = self.tableView.contentSize.height
        }
    }

    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sortButtonTapped() {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "По дате", style: .default, handler: { [weak self] _ in
            self?.sortedBy = .byDate
            self?.sortTransactions()
        }))
        
        alert.addAction(UIAlertAction(title: "По сумме", style: .default, handler: { [weak self] _ in
            self?.sortedBy = .byAmount
            self?.sortTransactions()
        }))
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func selectStartDate() {
        showSwiftUIStyleDatePicker(isStart: true)
    }
    
    @objc private func selectEndDate() {
        showSwiftUIStyleDatePicker(isStart: false)
    }
    
    @objc private func showSortOptions() {
        let pickerVC = SortPickerViewController()
        pickerVC.selectedOption = sortedBy
        pickerVC.modalPresentationStyle = .overCurrentContext
        pickerVC.modalTransitionStyle = .crossDissolve
        
        pickerVC.completion = { [weak self] option in
            self?.sortedBy = option
            self?.sortTransactions()
        }
        
        present(pickerVC, animated: true)
    }
    
    private func sortTransactions() {
        switch sortedBy {
        case .byDate:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            transactions.sort { $0.amount > $1.amount }
        }
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableHeightConstraint?.constant = tableView.contentSize.height
        
        sortValueLabel.text = sortedBy == .byDate ? "По дате" : "По сумме"
    }
    
    private func showSwiftUIStyleDatePicker(isStart: Bool) {
        let datePickerVC = SwiftUIStyleDatePickerViewController()
        datePickerVC.modalPresentationStyle = .overCurrentContext
        datePickerVC.modalTransitionStyle = .crossDissolve
        datePickerVC.currentDate = isStart ? startDate : endDate
        datePickerVC.title = isStart ? "Выберите начальную дату" : "Выберите конечную дату"
        
        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        datePickerVC.onDateSelected = { [weak self] selectedDate in
            if isStart {
                self?.startDate = selectedDate
                self?.startDateButton.setTitle(self?.formatDate(selectedDate), for: .normal)
                
                if let endDate = self?.endDate, selectedDate > endDate {
                    self?.endDate = selectedDate
                    self?.endDateButton.setTitle(self?.formatDate(selectedDate), for: .normal)
                }
            } else {
                self?.endDate = selectedDate
                self?.endDateButton.setTitle(self?.formatDate(selectedDate), for: .normal)
                
                if let startDate = self?.startDate, selectedDate < startDate {
                    self?.startDate = selectedDate
                    self?.startDateButton.setTitle(self?.formatDate(selectedDate), for: .normal)
                }
            }
            
            self?.filterAndReload()
        }
        
        present(datePickerVC, animated: true)
    }
    
    // MARK: - Helpers
    
    private func updatePieChartData() {
        var categoryTotals: [String: Decimal] = [:]
        
        for transaction in transactions {
            if let category = categories.first(where: { $0.id == transaction.categoryId }),
               let amount = Decimal(string: transaction.amount) {
                categoryTotals[category.name, default: 0] += amount
            }
        }
        
        let sortedCategories = categoryTotals.sorted { $0.value > $1.value }
        let chartData = sortedCategories.map { PieChartEntity(value: $0.value, label: $0.key) }
        
        animatePieChartUpdate(with: chartData)
    }
    
    private func animatePieChartUpdate(with newData: [PieChartEntity]) {
        UIView.animate(withDuration: 0.2, animations: {
            self.pieChartView.alpha = 0
            self.pieChartView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            self.pieChartView.entities = newData
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: {
                self.pieChartView.alpha = 1
                self.pieChartView.transform = .identity
            })
        })
    }
    
    private func updateTotalAmount() {
        var totalAmount: Decimal {
            transactions.reduce(Decimal.zero) { result, transaction in
                if let decimalAmount = Decimal(string: transaction.amount) {
                    return result + decimalAmount
                } else {
                    return result
                }
            }
        }
        amountLabel.text = "\(formatAmount(totalAmount)) ₽"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionCell
        let transaction = transactions[indexPath.row]
        let category = categories.first { $0.id == transaction.categoryId }
        var totalAmount: Decimal {
            transactions.reduce(Decimal.zero) { result, transaction in
                if let decimalAmount = Decimal(string: transaction.amount) {
                    return result + decimalAmount
                } else {
                    return result
                }
            }
        }

        cell.configure(with: transaction, category: category, totalAmount: totalAmount)
        
        if indexPath.row == transactions.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
}
