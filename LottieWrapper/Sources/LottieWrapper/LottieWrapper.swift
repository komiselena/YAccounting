// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Lottie

public struct LottieView: UIViewRepresentable {
    let animationName: String
    var completion: (() -> Void)?

    public init(animationName: String, completion: (() -> Void)? = nil) {
        self.animationName = animationName
        self.completion = completion
    }

    public func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = .playOnce
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundColor = .clear
        animationView.play { completed in
            if completed {
                completion?()
            }
        }
        return animationView
    }

    public func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
