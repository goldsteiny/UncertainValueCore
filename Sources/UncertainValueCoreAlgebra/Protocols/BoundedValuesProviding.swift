//
//  BoundedValuesProviding.swift
//  UncertainValueCoreAlgebra
//
//  Protocol for Double-based values with bounds.
//

import Foundation

public protocol BoundedValuesProviding: ValueProviding, BoundsProviding where Scalar == Double {}

public struct BoundedDouble: BoundedValuesProviding, Sendable, Equatable, Hashable {
    public let value: Double
    public let lowerBound: Double
    public let upperBound: Double

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

public extension BoundedDouble {
    init<T: BoundedValuesProviding>(from value: T) {
        let lower = value.lowerBound.isFinite ? value.lowerBound : value.value
        let upper = value.upperBound.isFinite ? value.upperBound : value.value
        self.init(value: value.value, lowerBound: lower, upperBound: upper)
    }
}

extension Double: BoundedValuesProviding {
    public var value: Double { self }
    public var lowerBound: Double { self }
    public var upperBound: Double { self }
}
