//
//  ChartValue.swift
//  BoundedValuesCharts
//
//  Scalar value with optional error bounds.
//

import Foundation
import UncertainValueCoreAlgebra

public struct ChartValue: Sendable, Equatable, Hashable {
    public let value: Double
    public let lowerBound: Double
    public let upperBound: Double

    public var hasErrorBounds: Bool {
        lowerBound != upperBound
    }

    public var isSinglePoint: Bool {
        lowerBound == upperBound
    }

    public init(_ value: Double) {
        self.value = value
        self.lowerBound = value
        self.upperBound = value
    }

    public init(value: Double, lowerBound: Double, upperBound: Double) {
        self.value = value
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

public extension ChartValue {
    init<T: BoundedValuesProviding>(from value: T) {
        let lower = value.lowerBound.isFinite ? value.lowerBound : value.value
        let upper = value.upperBound.isFinite ? value.upperBound : value.value
        self.init(value: value.value, lowerBound: lower, upperBound: upper)
    }
}
