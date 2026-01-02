// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "UncertainValueCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "UncertainValueCore",
            targets: ["UncertainValueCore"]
        ),
        .library(
            name: "UncertainValueConvenience",
            targets: ["UncertainValueConvenience"]
        ),
        .library(
            name: "MultiplicativeUncertainValue",
            targets: ["MultiplicativeUncertainValue"]
        ),
        .library(
            name: "UncertainValueStatistics",
            targets: ["UncertainValueStatistics"]
        )
    ],
    targets: [
        .target(
            name: "UncertainValueCore"
        ),
        .target(
            name: "UncertainValueConvenience",
            dependencies: ["UncertainValueCore"]
        ),
        .target(
            name: "MultiplicativeUncertainValue",
            dependencies: ["UncertainValueCore"]
        ),
        .target(
            name: "UncertainValueStatistics",
            dependencies: ["UncertainValueCore", "MultiplicativeUncertainValue"]
        ),
        .testTarget(
            name: "UncertainValueCoreTests",
            dependencies: ["UncertainValueCore", "UncertainValueStatistics"]
        ),
        .testTarget(
            name: "UncertainValueConvenienceTests",
            dependencies: ["UncertainValueConvenience"]
        ),
        .testTarget(
            name: "MultiplicativeUncertainValueTests",
            dependencies: ["MultiplicativeUncertainValue"]
        ),
        .testTarget(
            name: "UncertainValueStatisticsTests",
            dependencies: ["UncertainValueStatistics"]
        )
    ]
)
