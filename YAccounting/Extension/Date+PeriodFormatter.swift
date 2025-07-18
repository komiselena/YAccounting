//
//  Date+PeriodFormatter.swift
//  YAccounting
//
//  Created by Mac on 15.07.2025.
//
import SwiftUI

extension Date {
    func formatPeriod() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
