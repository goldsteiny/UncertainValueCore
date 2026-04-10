//
//  BoundsProviding.swift
//  UncertainValueSupport
//
//  Bounds abstractions for displaying uncertainty intervals.
//

import Foundation

public protocol BoundsProviding: ValueProviding {
    var lowerBound: Scalar { get }
    var upperBound: Scalar { get }
}

public extension BoundsProviding {
    @inlinable
    var bounds: ClosedRange<Scalar> {
        lowerBound...upperBound
    }

    @inlinable
    var isSinglePoint: Bool {
        lowerBound == upperBound
    }
}

public extension BoundsProviding where Self: AbsoluteErrorProviding {
    @inlinable
    var lowerBound: Scalar {
        value - absoluteError
    }

    @inlinable
    var upperBound: Scalar {
        value + absoluteError
    }
}

public extension BoundsProviding where Self: MultiplicativeErrorProviding {
    @inlinable
    var lowerBound: Scalar {
        Swift.min(value * multiplicativeError, value / multiplicativeError)
    }

    @inlinable
    var upperBound: Scalar {
        Swift.max(value * multiplicativeError, value / multiplicativeError)
    }
}

public protocol BoundedValuesProviding: ValueProviding, BoundsProviding where Scalar == Double {}

public struct BoundedDouble: BoundedValuesProviding, Equatable, Hashable {
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

    public init<T: BoundedValuesProviding>(from value: T) {
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

public extension Array where Element == Double {
    @inlinable
    var asBoundedValues: [Double?] {
        map(Optional.some)
    }
}
