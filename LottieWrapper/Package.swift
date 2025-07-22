// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LottieWrapper",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "LottieWrapper",
            targets: ["LottieWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.3.0")
    ],
    targets: [
        .target(
            name: "LottieWrapper",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ]
        ),
        .testTarget(
            name: "LottieWrapperTests",
            dependencies: ["LottieWrapper"]
        ),
    ]
)
