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
    /// - Throws: `UncertainValueError.invalidValue` if value is 0,
    ///           `UncertainValueError.nonFinite` if value or error is non-finite.
    public var asMultiplicative: MultiplicativeUncertainValue {
        get throws {
            guard value != 0 else { throw UncertainValueError.invalidValue }
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
    ///   - sign: Sign of the result (defaults to .plus).
    /// - Returns: A new MultiplicativeUncertainValue constructed from the log-space representation.
    /// - Throws: `UncertainValueError.nonFinite` if logAbs values are non-finite.
    public static func exp(_ logAbs: UncertainValue, withResultSign sign: FloatingPointSign = .plus) throws -> MultiplicativeUncertainValue {
        try .init(logAbs: logAbs, sign: sign)
    }

    /// Creates a MultiplicativeUncertainValue from log-space representation without validation.
    ///
    /// Use this when you have already validated the inputs or they come from a trusted source.
    /// - Parameters:
    ///   - logAbs: Log of absolute value with error in log-space. Must be finite.
    ///   - sign: Sign of the result (defaults to .plus).
    /// - Precondition: logAbs.value.isFinite, logAbs.absoluteError.isFinite
    /// - Returns: A new MultiplicativeUncertainValue constructed from the log-space representation.
    public static func uncheckedExp(_ logAbs: UncertainValue, withResultSign sign: FloatingPointSign = .plus) -> MultiplicativeUncertainValue {
        .unchecked(logAbs: logAbs, sign: sign)
    }
}
