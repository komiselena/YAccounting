//
//  View+hLeading.swift
//  YAccounting
//
//  Created by Mac on 15.06.2025.
//

import SwiftUI

extension View{
    func hLeading() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    func hTrailing() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

}
