import UIKit

class AnalysisViewController: UIViewController {
    // Начальная и конечная даты, выбранные пользователем
    private var startDate: Date = Date()
    private var endDate: Date = Date()

    /// Все транзакции, переданные на экран
    private let allTransactions: [Transaction]

    /// Все категории, необходимые для отображения эмодзи/названий
    private let categories: [Category]

    /// Отфильтрованные транзакции, которые отображаются в таблице
    private var transactions: [Transaction] = []

    /// Текущий критерий сортировки
    private var sortedBy: SortOption = .date

    private enum SortOption {
        case date
        case amount
    }

    // MARK: – Initialiser
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
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Контейнер для списка операций с белым фоном, как у блока периода
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
        tableView.tableFooterView = UIView() // убираем пустые сепараторы
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        return tableView
    }()
    
    /// Ограничение высоты таблицы
    private var tableHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
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
    
    // MARK: - Setup
    private func setupNavigationBar() {
        // Устанавливаем заголовок сразу в viewDidLoad
        title = "Анализ"
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = sortButton
        
        // Принудительно обновляем навигационную панель
        navigationController?.navigationBar.setNeedsLayout()
        navigationController?.navigationBar.layoutIfNeeded()
    }
    
    private func setupUI() {
        // Общий фон на весь экран, игнорируя safe area
        view.backgroundColor = .systemGroupedBackground
        
        // Настраиваем дату на кнопках после вычисления диапазона в init
        startDateButton.setTitle(formatDate(startDate), for: .normal)
        endDateButton.setTitle(formatDate(endDate), for: .normal)
        
        view.addSubview(periodView)
        
        // Используем вертикальный стек для имитации формы SwiftUI
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.distribution = .fill
        verticalStack.alignment = .fill
        verticalStack.spacing = 12
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Первая строка – начало периода
        let startRow = makeRow(titleLabel: startLabel, valueView: startDateButton, isLast: false)
        // Вторая строка – конец периода
        let endRow = makeRow(titleLabel: endLabel, valueView: endDateButton, isLast: false)
        // Третья строка – сумма
        let sumTitle = UILabel()
        sumTitle.text = "Сумма"
        sumTitle.font = .systemFont(ofSize: 16)
        let sumRow = makeRow(titleLabel: sumTitle, valueView: amountLabel, isLast: true)
        
        [startRow, endRow, sumRow].forEach { verticalStack.addArrangedSubview($0) }
        
        periodView.backgroundColor = .systemBackground // Ячейка формы белая
        periodView.addSubview(verticalStack)
        
        view.addSubview(operationsLabel)
        view.addSubview(operationsContainer)
        operationsContainer.addSubview(tableView)
        
        // Констрейнты для стека
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: periodView.topAnchor, constant: 16),
            verticalStack.leadingAnchor.constraint(equalTo: periodView.leadingAnchor, constant: 16),
            verticalStack.trailingAnchor.constraint(equalTo: periodView.trailingAnchor, constant: -16),
            verticalStack.bottomAnchor.constraint(equalTo: periodView.bottomAnchor, constant: -16),
            
            operationsLabel.topAnchor.constraint(equalTo: periodView.bottomAnchor, constant: 24),
            operationsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Контейнер операций
            operationsContainer.topAnchor.constraint(equalTo: operationsLabel.bottomAnchor, constant: 8),
            operationsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            operationsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            operationsContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // таблица внутри контейнера
            tableView.topAnchor.constraint(equalTo: operationsContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: operationsContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: operationsContainer.trailingAnchor)
        ])
        
        // Высота таблицы
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint?.isActive = true
        operationsContainer.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            periodView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            periodView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            periodView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            operationsLabel.topAnchor.constraint(equalTo: periodView.bottomAnchor, constant: 24),
            operationsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            operationsContainer.topAnchor.constraint(equalTo: operationsLabel.bottomAnchor, constant: 8),
            operationsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            operationsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            operationsContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: operationsContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: operationsContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: operationsContainer.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sortButtonTapped() {
        let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "По дате", style: .default, handler: { [weak self] _ in
            self?.sortedBy = .date
            self?.sortTransactions()
        }))
        
        alert.addAction(UIAlertAction(title: "По сумме", style: .default, handler: { [weak self] _ in
            self?.sortedBy = .amount
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
    
    // MARK: - SwiftUI Style Date Picker
    private func showSwiftUIStyleDatePicker(isStart: Bool) {
        let datePickerVC = SwiftUIStyleDatePickerViewController()
        datePickerVC.currentDate = isStart ? startDate : endDate
        datePickerVC.title = isStart ? "Выберите начальную дату" : "Выберите конечную дату"
        datePickerVC.modalPresentationStyle = .pageSheet
        
        // Настройка sheet для iOS 15+
        if #available(iOS 15.0, *) {
            if let sheet = datePickerVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
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
        
        // Для iPad / popover на iPhone (появится как sheet, но будет якорь на кнопку)
        if let pop = datePickerVC.popoverPresentationController {
            let sourceButton = isStart ? startDateButton : endDateButton
            pop.sourceView = sourceButton
            pop.sourceRect = sourceButton.bounds
            pop.permittedArrowDirections = .up
        }
        
        present(datePickerVC, animated: true)
    }
    
    // MARK: - Работа с данными
    /// Фильтруем транзакции по диапазону дат, пересчитываем сумму и сортируем.
    private func filterAndReload() {
        transactions = allTransactions.filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
        updateTotalAmount()
        sortTransactions()
    }
    
    private func updateTotalAmount() {
        let totalAmount = transactions.reduce(Decimal(0)) { $0 + $1.amount }
        amountLabel.text = "\(formatAmount(totalAmount)) ₽"
    }
    
    private func sortTransactions() {
        switch sortedBy {
        case .date:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .amount:
            transactions.sort { $0.amount > $1.amount }
        }
        tableView.reloadData()
        // Обновляем высоту контейнера
        tableView.layoutIfNeeded()
        tableHeightConstraint?.constant = tableView.contentSize.height
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

// MARK: - SwiftUI Style Date Picker View Controller
class SwiftUIStyleDatePickerViewController: UIViewController {
    var currentDate: Date = Date()
    var onDateSelected: ((Date) -> Void)?
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var calendarView: UICalendarView = {
        let calendar = UICalendarView()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.fontDesign = .default
        return calendar
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отмена", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @available(iOS 16.0, *)
    private var singleDateSelection: UICalendarSelectionSingleDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCalendar()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(calendarView)
        view.addSubview(doneButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            calendarView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendarView.heightAnchor.constraint(equalToConstant: 300),
            
            doneButton.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 30),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 10),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @available(iOS 16.0, *)
    private func setupCalendar() {
        guard #available(iOS 16.0, *) else {
            // Fallback для более старых версий iOS
            setupFallbackDatePicker()
            return
        }
        
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        singleDateSelection = selection
        
        // Устанавливаем текущую выбранную дату
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        selection.selectedDate = dateComponents
        
        // Доступный диапазон
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
    }
    
    private func setupFallbackDatePicker() {
        // Удаляем календарь и добавляем обычный date picker для старых версий
        calendarView.removeFromSuperview()
        
        datePicker.date = currentDate
        view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            doneButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 50)
        ])
    }
    
    @objc private func doneButtonTapped() {
        let selectedDate: Date
        
        if #available(iOS 16.0, *), let dateComponents = singleDateSelection?.selectedDate {
            selectedDate = Calendar.current.date(from: dateComponents) ?? currentDate
        } else {
            selectedDate = datePicker.date
        }
        
        onDateSelected?(selectedDate)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICalendarSelectionSingleDateDelegate
@available(iOS 16.0, *)
extension SwiftUIStyleDatePickerViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        return true
    }
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        // Не требуется дополнительной логики
    }
}

// MARK: - UITableViewDataSource & Delegate
extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionCell
        let transaction = transactions[indexPath.row]
        let category = categories.first { $0.id == transaction.categoryId }
        cell.configure(with: transaction, category: category, totalAmount: transactions.reduce(0) { $0 + $1.amount })
        
        // Скрываем линию под последней ячейкой
        if indexPath.row == transactions.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
        
        return cell
    }
}

// MARK: - Custom Cell
class TransactionCell: UITableViewCell {
    // MARK: - Subviews
    private let emojiContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 16
        return view
    }()
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    private let percentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        return label
    }()
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .none
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupUI() {
        contentView.addSubview(emojiContainer)
        emojiContainer.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(percentLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            emojiContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiContainer.widthAnchor.constraint(equalToConstant: 32),
            emojiContainer.heightAnchor.constraint(equalToConstant: 32),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            percentLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            percentLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -4),

            amountLabel.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 2),
            amountLabel.trailingAnchor.constraint(equalTo: percentLabel.trailingAnchor)
        ])
    }

    // MARK: - Configure
    func configure(with transaction: Transaction, category: Category?, totalAmount: Decimal) {
        // Emoji
        if let cat = category {
            emojiLabel.text = String(cat.emoji)
            titleLabel.text = cat.name
        } else {
            emojiLabel.text = "💸"
            titleLabel.text = transaction.comment ?? "Операция"
        }

        subtitleLabel.text = transaction.comment ?? "Без описания"

        // Percent
        let percent: Double
        if totalAmount != 0 {
            let ratio = (transaction.amount / totalAmount) as NSDecimalNumber
            percent = ratio.doubleValue * 100
        } else {
            percent = 0
        }
        percentLabel.text = String(format: "%.0f%%", percent)

        // Amount
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        let amountString = formatter.string(from: transaction.amount as NSDecimalNumber) ?? "\(transaction.amount)"
        amountLabel.text = "\(amountString) ₽"
    }
}

// MARK: - Helpers UI
extension AnalysisViewController {
    /// Создаёт горизонтальный ряд из заголовка и значения, разделённых пробелом
    private func makeRow(titleLabel: UILabel, valueView: UIView, isLast: Bool) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Заголовок
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stack.addArrangedSubview(titleLabel)

        // Spacer
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(spacer)

        // Значение / кнопка
        valueView.setContentHuggingPriority(.required, for: .horizontal)
        stack.addArrangedSubview(valueView)

        // Стили для кнопок дат
        if let button = valueView as? UIButton {
            button.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            button.layer.cornerRadius = 8
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        }

        // Добавляем разделительную линию снизу, имитируя UITableView.separator
        if !isLast {
            let separator = UIView()
            separator.backgroundColor = UIColor.systemGray4
            separator.translatesAutoresizingMaskIntoConstraints = false
            stack.addSubview(separator)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 0.5),
                separator.leadingAnchor.constraint(equalTo: stack.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: stack.bottomAnchor)
            ])
        }

        return stack
    }
}

