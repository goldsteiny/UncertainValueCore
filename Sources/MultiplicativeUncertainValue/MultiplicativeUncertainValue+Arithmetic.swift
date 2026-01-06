//
//  MultiplicativeUncertainValue+Arithmetic.swift
//  MultiplicativeUncertainValue
//
//  Arithmetic operations in log-space.
//

import Foundation
import UncertainValueCore

// MARK: - Unary Operations

extension MultiplicativeUncertainValue {
    /// Absolute value |x|.
    /// - Returns: New value with same logAbs, sign forced to .plus.
    public var absolute: MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(logAbs: logAbs, sign: .plus)
    }

    /// Absolute value |x|.
    /// - Returns: New value with same logAbs, sign forced to .plus.
    public var absValue: MultiplicativeUncertainValue {
        absolute
    }
    
    /// Negation (-x).
    /// - Returns: New value with flipped sign, same logAbs.
    public var negative: MultiplicativeUncertainValue {
        let newSign: FloatingPointSign = (sign == .plus) ? .minus : .plus
        return MultiplicativeUncertainValue(logAbs: logAbs, sign: newSign)
    }

    /// Reciprocal (1/x) in log-space, assuming a non-zero value.
    ///
    /// Always succeeds since `MultiplicativeUncertainValue` cannot represent zero.
    public var reciprocalAssumingNonZero: MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(logAbs: logAbs.negative, sign: sign)
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
    /// - Parameter alpha: Scale factor (must be non-zero).
    /// - Returns: Scaled value with same multiplicative error.
    /// - Precondition: lambda != 0 (MultiplicativeUncertainValue cannot represent zero).
    public func scaledUp(by alpha: Double) -> MultiplicativeUncertainValue {
        precondition(alpha != 0, "Cannot scale to zero: MultiplicativeUncertainValue cannot represent 0")
        precondition(alpha.isFinite, "Scale factor must be finite")

        let newLogValue = logAbs.value + Darwin.log(abs(alpha))
        let newLogAbs = UncertainValue(newLogValue, absoluteError: logAbs.absoluteError)
        let newSign = [sign, alpha.sign].product()

        return MultiplicativeUncertainValue(logAbs: newLogAbs, sign: newSign)
    }

    /// Divides by a non-zero constant.
    /// - Parameter lambda: Divisor (must be non-zero).
    /// - Returns: Scaled value with same multiplicative error.
    /// - Precondition: lambda != 0.
    public func scaledDown(by lambda: Double) -> MultiplicativeUncertainValue {
        precondition(lambda != 0, "Cannot divide by zero")
        return scaledUp(by: 1.0 / lambda)
    }
}

// MARK: - Exponentiation

extension MultiplicativeUncertainValue {
    /// Raises to an integer power.
    /// - Parameter n: Integer exponent.
    /// - Returns: Result in log-space, or nil if result is non-finite.
    /// - Note: Sign is .plus if n is even, original sign if n is odd.
    public func raised(to n: Int) -> MultiplicativeUncertainValue? {
        guard let absPowered = absolute.raised(to: Double(n)) else { return nil }
        let newSign: FloatingPointSign = (n % 2 == 0) ? .plus : sign
        return MultiplicativeUncertainValue(logAbs: absPowered.logAbs, sign: newSign)
    }

    /// Raises to a real power.
    /// - Parameter p: Real exponent.
    /// - Returns: Result in log-space, or nil if sign is negative or result is non-finite.
    /// - Note: Only valid for positive values (sign == .plus).
    public func raised(to p: Double) -> MultiplicativeUncertainValue? {
        guard sign == .plus else { return nil }

        let newLogAbs = logAbs.multiplying(by: p)
        guard newLogAbs.value.isFinite && newLogAbs.absoluteError.isFinite else { return nil }

        return MultiplicativeUncertainValue(logAbs: newLogAbs, sign: .plus)
    }
}
