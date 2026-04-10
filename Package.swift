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
            name: "UncertainValueSupport",
            targets: ["UncertainValueSupport"]
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
    dependencies: [
        .package(path: "../AlgebraDomainLanguage")
    ],
    targets: [
        .target(
            name: "UncertainValueSupport",
            dependencies: [
                .product(name: "AlgebraDomainLanguage", package: "AlgebraDomainLanguage")
            ]
        ),
        .target(
            name: "UncertainValueCore",
            dependencies: [
                "UncertainValueSupport",
                .product(name: "AlgebraDomainLanguage", package: "AlgebraDomainLanguage")
            ]
        ),
        .target(
            name: "UncertainValueConvenience",
            dependencies: ["UncertainValueCore", "UncertainValueSupport"]
        ),
        .target(
            name: "MultiplicativeUncertainValue",
            dependencies: [
                "UncertainValueCore",
                "UncertainValueSupport",
                .product(name: "AlgebraDomainLanguage", package: "AlgebraDomainLanguage")
            ]
        ),
        .target(
            name: "UncertainValueStatistics",
            dependencies: [
                "UncertainValueCore",
                "MultiplicativeUncertainValue",
                "UncertainValueSupport",
                .product(name: "AlgebraDomainLanguage", package: "AlgebraDomainLanguage")
            ]
        ),
        .target(
            name: "BoundedValuesCharts",
            dependencies: ["UncertainValueSupport"],
            path: "Sources/UncertainValueCharts"
        ),
        .testTarget(
            name: "UncertainValueSupportTests",
            dependencies: ["UncertainValueSupport"]
        ),
        .testTarget(
            name: "UncertainValueCoreTests",
            dependencies: ["UncertainValueCore", "UncertainValueSupport", "UncertainValueStatistics"]
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
            dependencies: ["BoundedValuesCharts", "UncertainValueSupport"]
        )
    ]
)
