//
//  SwiftUIStyleDatePickerViewController.swift
//  YAccounting
//
//  Created by Mac on 11.07.2025.
//

import UIKit

class SwiftUIStyleDatePickerViewController: UIViewController {
    var currentDate: Date = Date()
    var onDateSelected: ((Date) -> Void)?
    
    private var singleDateSelection: UICalendarSelectionSingleDate?
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var calendarView: UICalendarView = {
        let calendar = UICalendarView()
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.calendar = Calendar(identifier: .gregorian)
        calendar.fontDesign = .default
        return calendar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCalendar()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        view.addSubview(containerView)
        containerView.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            containerView.heightAnchor.constraint(equalToConstant: 320),
            
            calendarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            calendarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupCalendar() {
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        singleDateSelection = selection
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: currentDate)
        selection.selectedDate = dateComponents
        
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
    }
}

extension SwiftUIStyleDatePickerViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        return true
    }
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        if let dateComponents = dateComponents, let date = Calendar.current.date(from: dateComponents) {
            onDateSelected?(date)
            dismiss(animated: true)
        }
    }
}
