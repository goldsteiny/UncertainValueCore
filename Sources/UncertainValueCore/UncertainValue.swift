//
//  UncertainValue.swift
//  UncertainValueCore
//
//  Core type representing a value with associated uncertainty.
//

import Foundation

// MARK: - Core Type

/// A value with associated 1-sigma uncertainty.
/// Represents measurements with error for physics lab calculations.
public struct UncertainValue: Hashable, Sendable, Codable {
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

    /// Relative 1-sigma uncertainty: sigma / |x|.
    /// - Returns 0 if both value and error are 0.
    /// - Returns +infinity if value is 0 but error is non-zero.
    public var relativeError: Double {
        let denom = abs(value)
        guard denom > 0 else { return absoluteError == 0 ? 0 : .infinity }
        return absoluteError / denom
    }

    /// Variance (squared uncertainty).
    public var variance: Double {
        absoluteError * absoluteError
    }
}

// MARK: - Common Constants

extension UncertainValue {
    /// Zero with no uncertainty.
    public static let zero = UncertainValue(0, absoluteError: 0)

    /// One with no uncertainty.
    public static let one = UncertainValue(1, absoluteError: 0)

    /// Pi with no uncertainty.
    public static let pi = UncertainValue(Double.pi, absoluteError: 0)

    /// Euler's number (e) with no uncertainty.
    public static let e = UncertainValue(M_E, absoluteError: 0)
}
