// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PieChart",
            targets: ["PieChart"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PieChart",
            dependencies: [],
            path: "Sources/PieChart",
            resources: [
                
            ]
        ),
        .testTarget(
            name: "PieChartTests",
            dependencies: ["PieChart"],
            path: "Tests/PieChartTests"
        )
    ]
)
