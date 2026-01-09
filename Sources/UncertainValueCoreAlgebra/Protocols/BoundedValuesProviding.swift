//
//  BoundedValuesProviding.swift
//  UncertainValueCoreAlgebra
//
//  Protocol for Double-based values with bounds.
//

import Foundation

public protocol BoundedValuesProviding: ValueProviding, BoundsProviding where Scalar == Double {}

public struct BoundedDouble: BoundedValuesProviding {
    public let value: Double
    public let lowerBound: Double
    public let upperBound: Double

    public init(value: Double, lowerBound: Double, upperBound: Double) {
        self.value = value
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

extension Double: BoundedValuesProviding {
    public var value: Double { self }
    public var lowerBound: Double { self }
    public var upperBound: Double { self }
}
