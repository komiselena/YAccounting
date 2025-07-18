//
//  AlertState.swift
//  YAccounting
//
//  Created by Mac on 17.07.2025.
//

import SwiftUI

struct AlertState: Identifiable {
    enum AlertType {
        case validation
        case deleteConfirmation
        case error
        case info

    }
    
    let id = UUID()
    let type: AlertType
    var title: String
    var message: String
}

