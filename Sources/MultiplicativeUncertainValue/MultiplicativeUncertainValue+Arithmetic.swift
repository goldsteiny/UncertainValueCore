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
    public var absValue: MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(logAbs: logAbs, sign: .plus)
    }
    
    /// Negation (-x).
    /// - Returns: New value with flipped sign, same logAbs.
    public var negative: MultiplicativeUncertainValue {
        let newSign: FloatingPointSign = (sign == .plus) ? .minus : .plus
        return MultiplicativeUncertainValue(logAbs: logAbs, sign: newSign)
    }

    /// Reciprocal (1/x) in log-space.
    /// - Returns: New value with negated logAbs, same sign.
    public var reciprocal: MultiplicativeUncertainValue {
        MultiplicativeUncertainValue(logAbs: logAbs.negative, sign: sign)
    }
}

// MARK: - Exponentiation

extension MultiplicativeUncertainValue {
    /// Raises to an integer power.
    /// - Parameter n: Integer exponent.
    /// - Returns: Result in log-space, or nil if result is non-finite.
    /// - Note: Sign is .plus if n is even, original sign if n is odd.
    public func raised(to n: Int) -> MultiplicativeUncertainValue? {
        guard let absPowered = absValue.raised(to: Double(n)) else { return nil }
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
