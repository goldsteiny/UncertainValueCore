//
//  MultiplicativeUncertainValue+Conversions.swift
//  MultiplicativeUncertainValue
//
//  Conversion sugar between additive and multiplicative representations.
//

import Foundation
import UncertainValueCore

// MARK: - Conversion Extensions

extension UncertainValue {
    /// Converts this additive uncertain value to multiplicative representation.
    /// - Returns: MultiplicativeUncertainValue, or nil if value == 0 or inputs are non-finite.
    /// - Note: Returns nil for non-finite values (NaN, infinity) rather than trapping.
    public var asMultiplicative: MultiplicativeUncertainValue? {
        guard value != 0 && value.isFinite && relativeError.isFinite else { return nil }
        let multError = 1 + relativeError
        guard multError.isFinite && multError >= 1 else { return nil }
        return MultiplicativeUncertainValue(
            value: value,
            multiplicativeError: multError
        )
    }
}

extension MultiplicativeUncertainValue {
    /// Converts this multiplicative uncertain value to additive representation.
    public var asUncertainValue: UncertainValue {
        UncertainValue.withRelativeError(value, relativeError)
    }
    
    /// Creates a MultiplicativeUncertainValue from log-space representation.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space.
    ///   - sign: Sign of the result (defaults to .plus).
    /// - Returns: A new MultiplicativeUncertainValue constructed from the log-space representation.
    public static func exp(_ logAbs: UncertainValue, withResultSign sign: FloatingPointSign = .plus) -> MultiplicativeUncertainValue {
        .init(logAbs: logAbs, sign: sign)
    }
}
