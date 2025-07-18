//
//  OfflineBanner.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//

import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .imageScale(.small)
            
            Text("Оффлайн режим")
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.small)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundColor(.white)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.7, green: 0.1, blue: 0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
