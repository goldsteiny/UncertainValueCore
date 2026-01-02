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
        .testTarget(
            name: "UncertainValueCoreTests",
            dependencies: ["UncertainValueCore"]
        ),
        .testTarget(
            name: "UncertainValueConvenienceTests",
            dependencies: ["UncertainValueConvenience"]
        ),
        .testTarget(
            name: "MultiplicativeUncertainValueTests",
            dependencies: ["MultiplicativeUncertainValue"]
        )
    ]
)
