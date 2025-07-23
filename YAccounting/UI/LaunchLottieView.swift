//
//  LaunchLottieView.swift
//  YAccounting
//
//  Created by Mac on 22.07.2025.
//

import SwiftUI
import LottieWrapper

struct LaunchLottieView: View {
    let animationName: String = "LottieAnimation"
    @Binding var showLaunchAnimation: Bool
    
    var body: some View {
        ZStack {
            Color.tint.opacity (1.0)
            ignoresSafeArea ()
            LottieView(animationName: animationName) {
                withAnimation {
                    showLaunchAnimation = false
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

//#Preview {
//    LaunchLottieView()
//}
