//
//  SpoilerAnimationManager.swift
//  YAccounting
//
//  Created by Mac on 23.06.2025.
//

import SwiftUI
import Combine

@MainActor
final class SpoilerAnimationManager: ObservableObject {
    @Published var isAnimating = false
    @Published var currentPhase = false

    private var timer: AnyCancellable?
    
    func startAnimation() {
        stopAnimation()
        isAnimating = true
        
        timer = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                withAnimation(.linear(duration: 0.15)) {
                    self?.currentPhase.toggle()
                }
            }
    }
    
    func stopAnimation() {
        timer?.cancel()
        timer = nil
        isAnimating = false
    }
}
