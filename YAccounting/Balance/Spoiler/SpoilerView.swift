//
//  SpoilerView.swift
//  YAccounting
//
//  Created by Mac on 23.06.2025.
//

import SwiftUI

struct SpoilerView: View {
    @ObservedObject var animationManager: SpoilerAnimationManager
    
    private let dotSize: CGFloat = 2
    private let spacing: CGFloat = 1.5
    private let width: CGFloat = 100
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<Int(width / (dotSize + spacing)), id: \.self) { _ in
                VStack(spacing: spacing) {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .frame(width: dotSize, height: dotSize)
                            .foregroundColor(animationManager.currentPhase ? .gray.opacity(0.7) : .gray.opacity(0.4))
                            .offset(
                                x: animationManager.currentPhase ? CGFloat.random(in: -2...2) : CGFloat.random(in: -2...2),
                                y: animationManager.currentPhase ? CGFloat.random(in: -2...2) : CGFloat.random(in: -2...2)
                            )
                    }
                }
            }
        }
        .onAppear {
            animationManager.startAnimation()
        }
        .onDisappear {
            animationManager.stopAnimation()
        }
    }
}

#Preview {
    SpoilerView(animationManager: SpoilerAnimationManager())
}
