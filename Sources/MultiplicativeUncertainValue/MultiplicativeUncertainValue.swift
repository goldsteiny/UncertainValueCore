//
//  MultiplicativeUncertainValue.swift
//  MultiplicativeUncertainValue
//
//  Log-domain representation of multiplicative uncertainty.
//

import Foundation
import Darwin
import UncertainValueCore
import UncertainValueCoreAlgebra

// MARK: - Core Type

/// Represents a non-zero value with multiplicative uncertainty in log-domain.
///
/// Unlike `UncertainValue`, this type cannot represent zero, so operations like
/// `reciprocal` and `dividing` always succeed without throwing.
///
/// Conforms to commutative multiplicative protocols for norm-aware multiplication.
public struct MultiplicativeUncertainValue: Sendable, CommutativeMultiplicativeGroupWithoutZero, Scalable, SignedRaisable, SignMagnitudeProviding, MultiplicativeErrorProviding {
    /// Scalar type for protocol conformance.
    public typealias Scalar = Double
    /// Norm strategy type for protocol conformance.
    public typealias Norm = NormStrategy
    /// Sign of the original value.
    public let signum: Signum

    /// Log of absolute value with propagated error.
    public let logAbs: UncertainValue

    /// Creates a multiplicative uncertain value.
    /// - Parameters:
    ///   - value: The central value (must be non-zero and finite).
    ///   - multiplicativeError: The multiplicative error factor (must be >= 1 and finite).
    /// - Throws:
    ///   - `UncertainValueError.invalidValue` if value is zero.
    ///   - `UncertainValueError.nonFinite` if value or multiplicativeError is non-finite.
    ///   - `UncertainValueError.invalidMultiplicativeError` if multiplicativeError < 1.
    public init(value: Double, multiplicativeError: Double) throws {
        guard value != 0 else {
            throw UncertainValueError.invalidValue
        }
        guard value.isFinite else {
            throw UncertainValueError.nonFinite
        }
        guard multiplicativeError >= 1 else {
            throw UncertainValueError.invalidMultiplicativeError
        }
        guard multiplicativeError.isFinite else {
            throw UncertainValueError.nonFinite
        }

        
        self.signum = value > 0 ? .positive : .negative
        self.logAbs = UncertainValue(
            Darwin.log(abs(value)),
            absoluteError: Darwin.log(multiplicativeError)
        )
    }

    /// Creates a multiplicative uncertain value directly from log-space representation.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space.
    ///   - sign: Sign of the value (.plus or .minus).
    /// - Throws: `UncertainValueError.nonFinite` if logAbs.value or logAbs.absoluteError is non-finite.
    /// - Note: Extreme logAbs values may cause overflow (to Inf) or underflow (to 0) when converted back to linear space.
    public init(logAbs: UncertainValue, signum: Signum) throws {
        guard logAbs.value.isFinite, logAbs.absoluteError.isFinite else {
            throw UncertainValueError.nonFinite
        }

        self.signum = signum
        self.logAbs = logAbs
    }

    // MARK: - Unchecked Factory

    /// Private memberwise initializer for unchecked creation.
    private init(uncheckedLogAbs: UncertainValue, uncheckedSign: Signum) {
        self.logAbs = uncheckedLogAbs
        self.signum = uncheckedSign
    }

    /// Creates a multiplicative uncertain value without validation.
    ///
    /// Use this when you have already validated the inputs or they come from a trusted source.
    /// - Parameters:
    ///   - value: The central value. Must be non-zero and finite.
    ///   - multiplicativeError: The multiplicative error factor. Must be >= 1 and finite.
    /// - Precondition: value != 0, value.isFinite, multiplicativeError >= 1, multiplicativeError.isFinite
    /// - Returns: A new MultiplicativeUncertainValue.
    public static func unchecked(value: Double, multiplicativeError: Double) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(
            uncheckedLogAbs: UncertainValue(
                Darwin.log(abs(value)),
                absoluteError: Darwin.log(multiplicativeError)
            ),
            uncheckedSign: value > 0 ? .positive : .negative
        )
    }

    /// Creates a multiplicative uncertain value from log-space without validation.
    ///
    /// Use this when you have already validated the inputs or they come from a trusted source.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space. Must be finite.
    ///   - sign: Sign of the value (.plus or .minus).
    /// - Precondition: logAbs.value.isFinite, logAbs.absoluteError.isFinite
    /// - Returns: A new MultiplicativeUncertainValue.
    public static func unchecked(logAbs: UncertainValue, signum: Signum) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(uncheckedLogAbs: logAbs, uncheckedSign: signum)
    }

    /// The central value with sign applied.
    public var value: Double {
        let absValue = Darwin.exp(logAbs.value)
        return isPositive ? absValue :  -absValue
    }

    /// The multiplicative error factor.
    public var multiplicativeError: Double {
        Darwin.exp(logAbs.absoluteError)
    }

    
    public var flippedSign: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, signum: isPositive ? .negative : .positive)
    }
}

// MARK: - Common Constants

extension MultiplicativeUncertainValue {
    /// The multiplicative identity (one with no uncertainty).
    /// - value = 1.0, multiplicativeError = 1.0
    public static let one: MultiplicativeUncertainValue = .unchecked(value: 1.0, multiplicativeError: 1.0)
}
