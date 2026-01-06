//
//  MultiplicativeUncertainValue+Conversions.swift
//  MultiplicativeUncertainValue
//
//  Conversion sugar between additive and multiplicative representations.
//

import Foundation
import UncertainValueCore
import UncertainValueCoreAlgebra

// MARK: - Conversion Extensions

extension UncertainValue {
    /// Converts this additive uncertain value to multiplicative representation.
    /// - Returns: MultiplicativeUncertainValue.
    /// - Throws: `UncertainValueError.zeroInput` if value is 0,
    ///           `UncertainValueError.nonFinite` if value or error is non-finite.
    public var asMultiplicative: MultiplicativeUncertainValue {
        get throws {
            guard value != 0 else { throw UncertainValueError.zeroInput }
            guard value.isFinite && relativeError.isFinite else { throw UncertainValueError.nonFinite }
            let multError = 1 + relativeError
            guard multError.isFinite && multError >= 1 else { throw UncertainValueError.nonFinite }
            return .unchecked(value: value, multiplicativeError: multError)
        }
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
    ///   - signum: Sign of the result (defaults to .positive).
    /// - Returns: A new MultiplicativeUncertainValue constructed from the log-space representation.
    /// - Throws: `UncertainValueError.nonFinite` if logAbs values are non-finite.
    public static func exp(_ logAbs: UncertainValue, withResultSign signum: Signum = .positive) throws -> MultiplicativeUncertainValue {
        try .init(logAbs: logAbs, signum: signum)
    }

    /// Creates a MultiplicativeUncertainValue from log-space representation without validation.
    ///
    /// Use this when you have already validated the inputs or they come from a trusted source.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space. Must be finite.
    ///   - signum: Sign of the result (defaults to .positive).
    /// - Returns: A new MultiplicativeUncertainValue constructed from the log-space representation.
    public static func uncheckedExp(_ logAbs: UncertainValue, withResultSign signum: Signum = .positive) -> MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, signum: signum)
    }
}
