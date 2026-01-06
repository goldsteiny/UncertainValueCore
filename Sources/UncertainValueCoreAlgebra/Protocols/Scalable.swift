//
//  Scalable.swift
//  UncertainValueCoreAlgebra
//
//  Scaling by a scalar factor.
//

import Foundation

/// Types that can be scaled by a scalar factor.
public protocol Scalable: Sendable {
    associatedtype Scalar: BinaryFloatingPoint
    /// Scales up by a constant factor.
    /// - Parameter scalar: Scale factor (must be non-zero and finite).
    /// - Returns: Scaled value.
    /// - Throws: `UncertainValueError.invalidScale` if scalar is non-finite or, if relevant, zero.
    func scaledUp(by scalar: Scalar) throws -> Self

    /// Scales down by a constant factor.
    /// - Parameter scalar: Scale factor (must be non-zero and finite).
    /// - Returns: Scaled value.
    /// - Throws: `UncertainValueError.invalidScale` if scalar is zero or non-finite.
    func scaledDown(by scalar: Scalar) throws -> Self
}

public extension Scalable {
    /// Default implementation uses reciprocal scaling.
    /// - Throws: `UncertainValueError.invalidScale` if scalar is zero or non-finite.
    func scaledDown(by scalar: Scalar) throws -> Self {
        guard scalar != 0, scalar.isFinite else {
            throw UncertainValueError.invalidScale
        }
        return try scaledUp(by: 1 / scalar)
    }
}
