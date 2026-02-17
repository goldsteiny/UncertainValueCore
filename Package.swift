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
            name: "UncertainValueCoreAlgebra",
            targets: ["UncertainValueCoreAlgebra"]
        ),
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
        ),
        .library(
            name: "BoundedValuesCharts",
            targets: ["BoundedValuesCharts"]
        )
    ],
    targets: [
        .target(
            name: "UncertainValueCoreAlgebra"
        ),
        .target(
            name: "UncertainValueCore",
            dependencies: ["UncertainValueCoreAlgebra"]
        ),
        .target(
            name: "UncertainValueConvenience",
            dependencies: ["UncertainValueCore", "UncertainValueCoreAlgebra"]
        ),
        .target(
            name: "MultiplicativeUncertainValue",
            dependencies: ["UncertainValueCore", "UncertainValueCoreAlgebra"]
        ),
        .target(
            name: "UncertainValueStatistics",
            dependencies: ["UncertainValueCore", "MultiplicativeUncertainValue"]
        ),
        .target(
            name: "BoundedValuesCharts",
            dependencies: ["UncertainValueCoreAlgebra"],
            path: "Sources/UncertainValueCharts"
        ),
        .testTarget(
            name: "UncertainValueCoreAlgebraTests",
            dependencies: ["UncertainValueCoreAlgebra"]
        ),
        .testTarget(
            name: "UncertainValueCoreTests",
            dependencies: ["UncertainValueCore", "UncertainValueCoreAlgebra", "UncertainValueStatistics"]
        ),
        .testTarget(
            name: "UncertainValueConvenienceTests",
            dependencies: ["UncertainValueConvenience"]
        ),
        .testTarget(
            name: "MultiplicativeUncertainValueTests",
            dependencies: ["MultiplicativeUncertainValue", "UncertainValueConvenience"]
        ),
        .testTarget(
            name: "UncertainValueStatisticsTests",
            dependencies: ["UncertainValueStatistics"]
        ),
        .testTarget(
            name: "BoundedValuesChartsTests",
            dependencies: ["BoundedValuesCharts", "UncertainValueCoreAlgebra"]
        )
    ]
)
