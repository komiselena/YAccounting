//
//  FloatingSheet.swift
//  YAccounting
//
//  Created by Mac on 22.06.2025.
//

import SwiftUI

struct FloatingSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }

                VStack {
                    Spacer()
                    VStack {
                        content
                    }
                    .tint(.tint)
                    .padding(.vertical)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                    .frame(maxWidth: 350)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
