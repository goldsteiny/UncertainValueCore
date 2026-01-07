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
public struct MultiplicativeUncertainValue: Sendable, Hashable {
    /// Scalar type for protocol conformance.
    public typealias Scalar = Double
    /// Norm strategy type for protocol conformance.
    public typealias Norm = NormStrategy

    /// Sign of the original value.
    public let signum: Signum

    /// Log of absolute value with propagated error.
    public let logAbs: UncertainValue

    // MARK: - Throwing Initializers

    /// Creates a multiplicative uncertain value.
    /// - Parameters:
    ///   - value: The central value (must be non-zero and finite).
    ///   - multiplicativeError: The multiplicative error factor (must be >= 1 and finite).
    /// - Throws:
    ///   - `UncertainValueError.zeroInput` if value is zero.
    ///   - `UncertainValueError.nonFinite` if value or multiplicativeError is non-finite.
    ///   - `UncertainValueError.invalidMultiplicativeError` if multiplicativeError < 1.
    public init(value: Double, multiplicativeError: Double) throws {
        guard value != 0 else {
            throw UncertainValueError.zeroInput
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
    ///   - signum: Sign of the value (.positive or .negative).
    /// - Throws: `UncertainValueError.nonFinite` if logAbs.value or logAbs.absoluteError is non-finite.
    public init(logAbs: UncertainValue, signum: Signum) throws {
        guard logAbs.value.isFinite, logAbs.absoluteError.isFinite else {
            throw UncertainValueError.nonFinite
        }

        self.signum = signum
        self.logAbs = logAbs
    }

    // MARK: - Unchecked Factory

    /// Private memberwise initializer for unchecked creation.
    private init(uncheckedLogAbs: UncertainValue, uncheckedSignum: Signum) {
        self.logAbs = uncheckedLogAbs
        self.signum = uncheckedSignum
    }

    /// Creates a multiplicative uncertain value without validation.
    ///
    /// Use this when you have already validated the inputs or they come from a trusted source.
    /// - Parameters:
    ///   - value: The central value. Must be non-zero and finite.
    ///   - multiplicativeError: The multiplicative error factor. Must be >= 1 and finite.
    /// - Returns: A new MultiplicativeUncertainValue.
    public static func unchecked(value: Double, multiplicativeError: Double) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(
            uncheckedLogAbs: UncertainValue(
                Darwin.log(abs(value)),
                absoluteError: Darwin.log(multiplicativeError)
            ),
            uncheckedSignum: value > 0 ? .positive : .negative
        )
    }

    /// Creates a multiplicative uncertain value from log-space without validation.
    ///
    /// Use this when you have already validated the inputs or they come from a trusted source.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space. Must be finite.
    ///   - signum: Sign of the value (.positive or .negative).
    /// - Returns: A new MultiplicativeUncertainValue.
    public static func unchecked(logAbs: UncertainValue, signum: Signum) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(uncheckedLogAbs: logAbs, uncheckedSignum: signum)
    }
}

// MARK: - Computed Properties

extension MultiplicativeUncertainValue {
    /// The central value with sign applied.
    public var value: Double {
        let absValue = Darwin.exp(logAbs.value)
        return isPositive ? absValue : -absValue
    }

    /// The multiplicative error factor.
    public var multiplicativeError: Double {
        Darwin.exp(logAbs.absoluteError)
    }

    /// Same value with sign flipped.
    public var flippedSign: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, signum: signum.flipped)
    }

    /// Alias for `flippedSign` for protocol symmetry.
    public var negative: MultiplicativeUncertainValue {
        flippedSign
    }
}

// MARK: - Protocol Conformances

extension MultiplicativeUncertainValue:
    CommutativeMultiplicativeGroupWithoutZero,
    Scalable,
    SignedRaisable,
    SignMagnitudeProviding,
    MultiplicativeErrorProviding,
    BoundsProviding
{}

// MARK: - Static Constants (OneContaining)

extension MultiplicativeUncertainValue {
    /// The multiplicative identity (one with no uncertainty).
    public static let one: MultiplicativeUncertainValue = MultiplicativeUncertainValue.init(uncheckedLogAbs: .zero, uncheckedSignum: .positive)
    
    public var isOne: Bool { isPositive && logAbs.isZero }
}

// MARK: - Required by CommutativeMultiplicativeGroupWithoutZero

extension MultiplicativeUncertainValue {
    /// Computes the product of an array of values with error propagation using the specified norm.
    ///
    /// This is the primitive operation for the `CommutativeMultiplicativeGroupWithoutZero` protocol.
    /// Uses log-space formula: product = exp(sum(logAbs)), with sign = parity of negative count.
    ///
    /// - Parameters:
    ///   - values: Array of values to multiply.
    ///   - strategy: Norm strategy for combining log-space errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    public static func product(_ values: [MultiplicativeUncertainValue], using strategy: NormStrategy) -> MultiplicativeUncertainValue {
        guard !values.isEmpty else { return .one }
        let sumLogAbs = UncertainValue.sum(values.map(\.logAbs), using: strategy)
        let productSignum = values.map(\.signum).product()
        return .unchecked(logAbs: sumLogAbs, signum: productSignum)
    }

    /// Reciprocal (1/x) in log-space, assuming a non-zero value.
    ///
    /// Always succeeds since `MultiplicativeUncertainValue` cannot represent zero.
    public var reciprocalAssumingNonZero: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs.negative, signum: signum)
    }
}

// MARK: - Required by Scalable

extension MultiplicativeUncertainValue {
    /// Scales by a non-zero constant.
    /// - Parameter alpha: Scale factor (must be non-zero and finite).
    /// - Returns: Scaled value with same multiplicative error.
    /// - Throws: `UncertainValueError.invalidScale` if alpha is zero or non-finite.
    public func scaledUp(by alpha: Double) throws -> MultiplicativeUncertainValue {
        guard alpha != 0, alpha.isFinite else {
            throw UncertainValueError.invalidScale
        }

        let newLogValue = logAbs.value + Darwin.log(abs(alpha))
        guard newLogValue.isFinite else {
            throw UncertainValueError.nonFinite
        }
        let newLogAbs = UncertainValue(newLogValue, absoluteError: logAbs.absoluteError)
        let newSignum: Signum = (alpha > 0) ? signum : signum.flipped

        return .unchecked(logAbs: newLogAbs, signum: newSignum)
    }
}

// MARK: - Required by SignedRaisable

extension MultiplicativeUncertainValue {
    /// Raises to a real power.
    /// - Parameter p: Real exponent.
    /// - Returns: Result in log-space.
    /// - Throws: `UncertainValueError.negativeInput` if sign is negative,
    ///           `UncertainValueError.nonFinite` if result overflows/underflows.
    public func raised(to p: Double) throws -> MultiplicativeUncertainValue {
        guard isPositive else {
            throw UncertainValueError.negativeInput
        }

        let newLogAbs = logAbs.multiplying(by: p)
        guard newLogAbs.value.isFinite && newLogAbs.absoluteError.isFinite else {
            throw UncertainValueError.nonFinite
        }

        return .unchecked(logAbs: newLogAbs, signum: .positive)
    }
}

// MARK: - Required by SignMagnitudeProviding

extension MultiplicativeUncertainValue {
    /// Absolute value |x|.
    /// - Returns: New value with same logAbs, sign forced to .positive.
    public var absolute: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, signum: .positive)
    }
}

// MARK: - Array Helpers

extension Array where Element == MultiplicativeUncertainValue {
    /// Multiplies all values with error propagation using the specified norm.
    ///
    /// Delegates to `MultiplicativeUncertainValue.product(_:using:)`.
    ///
    /// - Parameter strategy: Norm strategy for combining log-space errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    public func product(using strategy: NormStrategy) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue.product(self, using: strategy)
    }
}
