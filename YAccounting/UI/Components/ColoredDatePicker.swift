//
//  ColoredDatePicker.swift
//  YAccounting
//
//  Created by Mac on 19.06.2025.
//

import SwiftUI

struct ColoredDatePicker: DatePickerStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack{
            configuration.label
            Spacer()
            DatePicker(
                "",
                selection: configuration.$selection,
                displayedComponents: configuration.displayedComponents
            )
                .background(backgroundColor)
                .cornerRadius(8)
        }
    }
}

extension DatePickerStyle where Self == ColoredDatePicker {
    static func colored(backgroundColor: Color) -> ColoredDatePicker {
        .init(backgroundColor: backgroundColor)
    }
}
