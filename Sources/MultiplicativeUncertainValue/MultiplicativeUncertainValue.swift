//
//  MultiplicativeUncertainValue.swift
//  MultiplicativeUncertainValue
//
//  Log-domain representation of multiplicative uncertainty.
//

import Foundation
import Darwin
import UncertainValueCore

// MARK: - Core Type

/// Represents a non-zero value with multiplicative uncertainty in log-domain.
///
/// Unlike `UncertainValue`, this type cannot represent zero, so operations like
/// `reciprocal` and `dividing` always succeed without throwing.
///
/// Conforms to `NonZeroInvertibleUncertainMultiplicative` to share protocol-derived list operations.
public struct MultiplicativeUncertainValue: Sendable, NonZeroInvertibleUncertainMultiplicative, SignMagnitudeProviding {
    /// Scalar type for protocol conformance.
    public typealias Scalar = Double
    /// Sign of the original value.
    public let sign: FloatingPointSign

    /// Log of absolute value with propagated error.
    public let logAbs: UncertainValue

    /// Creates a multiplicative uncertain value.
    /// - Parameters:
    ///   - value: The central value (must be non-zero and finite).
    ///   - multiplicativeError: The multiplicative error factor (must be >= 1 and finite).
    /// - Precondition: value != 0, value.isFinite, multiplicativeError >= 1, and multiplicativeError.isFinite.
    public init(value: Double, multiplicativeError: Double) {
        precondition(value != 0, "MultiplicativeUncertainValue requires value != 0")
        precondition(value.isFinite, "MultiplicativeUncertainValue requires finite value, got \(value)")
        precondition(multiplicativeError >= 1, "MultiplicativeUncertainValue requires multiplicativeError >= 1, got \(multiplicativeError)")
        precondition(multiplicativeError.isFinite, "MultiplicativeUncertainValue requires finite multiplicativeError, got \(multiplicativeError)")

        self.sign = value.sign
        self.logAbs = UncertainValue(
            Darwin.log(abs(value)),
            absoluteError: Darwin.log(multiplicativeError)
        )
    }

    /// Creates a multiplicative uncertain value directly from log-space representation.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space.
    ///   - sign: Sign of the value (.plus or .minus).
    /// - Precondition: logAbs.value and logAbs.absoluteError must be finite.
    public init(logAbs: UncertainValue, sign: FloatingPointSign) {
        precondition(logAbs.value.isFinite, "logAbs.value must be finite, got \(logAbs.value)")
        precondition(logAbs.absoluteError.isFinite, "logAbs.absoluteError must be finite, got \(logAbs.absoluteError)")

        self.sign = sign
        self.logAbs = logAbs
    }

    /// The central value with sign applied.
    public var value: Double {
        let absValue = Darwin.exp(logAbs.value)
        return sign == .minus ? -absValue : absValue
    }

    /// The multiplicative error factor.
    public var multiplicativeError: Double {
        Darwin.exp(logAbs.absoluteError)
    }

    /// Relative error as a fraction: multiplicativeError - 1.
    public var relativeError: Double {
        multiplicativeError - 1
    }

    /// Sign of the value (never zero).
    public var signum: Signum {
        sign == .minus ? .negative : .positive
    }
}

// MARK: - Common Constants

extension MultiplicativeUncertainValue {
    /// The multiplicative identity (one with no uncertainty).
    /// - value = 1.0, multiplicativeError = 1.0
    public static let one = MultiplicativeUncertainValue.exp(.zero)
}
