//
//  MultiplicativeUncertainValue+Arithmetic.swift
//  MultiplicativeUncertainValue
//
//  Arithmetic operations in log-space.
//

import Foundation
import UncertainValueCore
import UncertainValueCoreAlgebra

// MARK: - Unary Operations

extension MultiplicativeUncertainValue {
    /// Absolute value |x|.
    /// - Returns: New value with same logAbs, sign forced to .plus.
    public var absolute: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, sign: .plus)
    }

    /// Negation (-x).
    /// - Returns: New value with flipped sign, same logAbs.
    public var negative: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, sign: sign == .plus ? .minus : .plus)
    }

    /// Reciprocal (1/x) in log-space, assuming a non-zero value.
    ///
    /// Always succeeds since `MultiplicativeUncertainValue` cannot represent zero.
    public var reciprocalAssumingNonZero: MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs.negative, sign: sign)
    }

    /// Reciprocal (1/x) in log-space.
    ///
    /// Always succeeds since `MultiplicativeUncertainValue` cannot represent zero.
    public var reciprocal: MultiplicativeUncertainValue {
        reciprocalAssumingNonZero
    }
}

// MARK: - Binary Operations

extension MultiplicativeUncertainValue {
    /// Divides by another MultiplicativeUncertainValue using the specified norm strategy.
    ///
    /// Always succeeds since `MultiplicativeUncertainValue` cannot represent zero.
    ///
    /// - Parameters:
    ///   - other: Divisor value.
    ///   - strategy: Norm strategy for combining log-space errors.
    /// - Returns: Result of division.
    public func dividing(by other: MultiplicativeUncertainValue, using strategy: NormStrategy) -> MultiplicativeUncertainValue {
        multiplying(other.reciprocalAssumingNonZero, using: strategy)
    }
}

// MARK: - Scaling by Constant

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
        let newSign = [sign, alpha.sign].product()

        return .unchecked(logAbs: newLogAbs, sign: newSign)
    }
}

// MARK: - Exponentiation

extension MultiplicativeUncertainValue {
    /// Raises to an integer power.
    /// - Parameter n: Integer exponent.
    /// - Returns: Result in log-space.
    /// - Throws: `UncertainValueError.nonFinite` if result overflows/underflows.
    /// - Note: Sign is .plus if n is even, original sign if n is odd.
    public func raised(to n: Int) throws -> MultiplicativeUncertainValue {
        let absPowered = try absolute.raised(to: Double(n))
        let newSign: FloatingPointSign = (n % 2 == 0) ? .plus : sign
        return .unchecked(logAbs: absPowered.logAbs, sign: newSign)
    }

    /// Raises to a real power.
    /// - Parameter p: Real exponent.
    /// - Returns: Result in log-space.
    /// - Throws: `UncertainValueError.negativeInput` if sign is negative,
    ///           `UncertainValueError.nonFinite` if result overflows/underflows.
    /// - Note: Only valid for positive values (sign == .plus).
    public func raised(to p: Double) throws -> MultiplicativeUncertainValue {
        guard sign == .plus else {
            throw UncertainValueError.negativeInput
        }

        let newLogAbs = logAbs.multiplying(by: p)
        guard newLogAbs.value.isFinite && newLogAbs.absoluteError.isFinite else {
            throw UncertainValueError.nonFinite
        }

        return .unchecked(logAbs: newLogAbs, sign: .plus)
    }
}
