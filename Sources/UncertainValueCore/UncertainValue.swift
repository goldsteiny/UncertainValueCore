//
//  UncertainValue.swift
//  UncertainValueCore
//
//  Core type representing a value with associated uncertainty.
//

import Foundation
import UncertainValueCoreAlgebra

// MARK: - Core Type

/// A value with associated 1-sigma uncertainty.
/// Represents measurements with error for physics lab calculations.
///
/// Conforms to commutative algebra protocols for norm-aware addition and multiplication.
public struct UncertainValue: Hashable, Sendable, Codable, CommutativeAlgebraWithZero, SignedRaisable, UncertainValueCoreAlgebra.SignMagnitudeProviding, AbsoluteErrorProviding {
    /// Scalar type for protocol conformance.
    public typealias Scalar = Double
    /// Norm strategy type for protocol conformance.
    public typealias Norm = NormStrategy
    /// The central value.
    public let value: Double

    /// Absolute 1-sigma uncertainty (same unit as `value`). Always >= 0.
    public let absoluteError: Double

    /// Creates an UncertainValue with absolute error.
    /// - Parameters:
    ///   - value: The central value.
    ///   - absoluteError: The absolute uncertainty (will be stored as absolute value).
    public init(_ value: Double, absoluteError: Double) {
        self.value = value
        self.absoluteError = abs(absoluteError)
    }

    /// Creates an UncertainValue from relative error (as a fraction).
    /// - Parameters:
    ///   - value: The central value.
    ///   - relativeError: Relative error as fraction (e.g., 0.05 for 5%).
    /// - Formula: absoluteError = |value * relativeError|
    public static func withRelativeError(_ value: Double, _ relativeError: Double) -> UncertainValue {
        UncertainValue(value, absoluteError: abs(value * relativeError))
    }

    /// Creates an UncertainValue with combined absolute and relative errors.
    /// - Parameters:
    ///   - value: The central value.
    ///   - absoluteError: Absolute uncertainty component.
    ///   - relativeError: Relative error as fraction (e.g., 0.05 for 5%).
    /// - Formula: totalAbsoluteError = |absoluteError| + |value * relativeError|
    public static func withCombinedErrors(
        _ value: Double,
        absoluteError: Double,
        relativeError: Double
    ) -> UncertainValue {
        let totalAbsError = abs(absoluteError) + abs(value * relativeError)
        return UncertainValue(value, absoluteError: totalAbsError)
    }
    
    /// Sign of the central value.
    public var signum: Signum {
        if value == 0 {
            return .zero
        }
        return value.sign == .minus ? .negative : .positive
    }
    
    /// Absolute value of the central value (error unchanged).
    public var absolute: UncertainValue {
        UncertainValue(absoluteValue, absoluteError: absoluteError)
    }
}


// MARK: - Single-Scalar Protocol-Required Operations

extension UncertainValue {
    
    /// Scales up by a constant factor.
    /// - Returns: Result, or nil if scalar is zero or non-finite.
    public func scaledUp(by scalar: Double) -> UncertainValue? {
        guard scalar != 0, scalar.isFinite else { return nil }
        return multiplying(by: scalar)
    }
    
    /// Raises value to a real power with error propagation.
    /// - Parameter p: The exponent.
    /// - Returns: Result with propagated error, or nil if base <= 0 or non-finite.
    public func raised(to p: Double) -> UncertainValue? {
        if value == 0 {
            guard absoluteError == 0, p > 0 else { return nil }
            return .zero
        }

        guard value > 0 else { return nil }

        let newValue = pow(value, p)
        guard newValue.isFinite else { return nil }
        
        let newRelError = abs(p) * relativeError
        guard newRelError.isFinite else { return nil }
        
        return UncertainValue.withRelativeError(newValue, newRelError)
    }
}


// MARK: - Protocol-Required Static Constants & Methods

extension UncertainValue {
    /// Zero with no uncertainty.
    public static let zero = UncertainValue(0, absoluteError: 0)

    /// One with no uncertainty.
    public static let one = UncertainValue(1, absoluteError: 0)

    /// Sums an array of values with error propagation using the specified norm.
    ///
    /// This is the primitive operation for the `CommutativeAdditiveGroup` protocol.
    /// Uses direct formula: sum.value = Σ values, sum.error = norm(errors).
    ///
    /// - Parameters:
    ///   - values: Array of values to sum.
    ///   - strategy: The norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty. Empty array returns `.zero`.
    public static func sum(_ values: [UncertainValue], using strategy: NormStrategy) -> UncertainValue {
        guard !values.isEmpty else { return .zero }
        let sumValue = values.map(\.value).sum
        let combinedError = norm(values.map(\.absoluteError), using: strategy)
        return UncertainValue(sumValue, absoluteError: combinedError)
    }

    /// Computes the product of an array of values with error propagation using the specified norm.
    ///
    /// This is the primitive operation for the `CommutativeMultiplicativeGroupWithZero` protocol.
    /// Uses direct formula: product.value = Π values, product.relError = norm(relErrors).
    ///
    /// - Parameters:
    ///   - values: Array of values to multiply.
    ///   - strategy: The norm strategy for combining relative errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    public static func product(_ values: [UncertainValue], using strategy: NormStrategy) -> UncertainValue {
        guard !values.isEmpty else { return .one }
        let productValue = values.map(\.value).product
        let combinedRelError = norm(values.map(\.relativeError), using: strategy)
        return UncertainValue.withRelativeError(productValue, combinedRelError)
    }
}

// MARK: - Common Constants

extension UncertainValue {

    /// Pi with no uncertainty.
    public static let pi = UncertainValue(Double.pi, absoluteError: 0)

    /// Euler's number (e) with no uncertainty.
    public static let e = UncertainValue(M_E, absoluteError: 0)
}

// MARK: - Overwrite with more efficient or non-optional implementations

extension UncertainValue {

    /// Negates the value (error unchanged).
    public var negative: UncertainValue {
        UncertainValue(-value, absoluteError: absoluteError)
    }

    /// Computes reciprocal (1/x) with error propagation.
    /// - Returns: Reciprocal with propagated error.
    /// - Throws: `UncertainValueError.divisionByZero` when value is 0.
    /// - Formula: relError(1/x) = relError(x)
    public var reciprocal: UncertainValue {
        get throws {
            guard value != 0 else { throw UncertainValueError.divisionByZero }
            return UncertainValue.withRelativeError(1 / value, relativeError)
        }
    }
    
    /// Scales down by a constant factor.
    /// - Returns: Result, or nil if scalar is zero or non-finite.
    public func scaledDown(by scalar: Double) -> UncertainValue? {
        guard scalar != 0, scalar.isFinite else { return nil }
        return dividing(by: scalar)
    }
}
