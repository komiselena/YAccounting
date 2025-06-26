//
//  SwipeToDismiss.swift
//  YAccounting
//
//  Created by Mac on 22.06.2025.
//


import SwiftUI

struct SwipeToDismiss: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { drag in
                        withAnimation {
                            if drag.translation.height > 100 {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                                withAnimation(.easeInOut){
                                    isPresented = false
                                }
                            }
                        }
                    }
            )
    }
}

extension View {
    func swipeToDismiss(_ isPresented: Binding<Bool>, onDismiss: @escaping () -> Void = {}) -> some View {
        modifier(SwipeToDismiss(isPresented: isPresented))
    }
}
