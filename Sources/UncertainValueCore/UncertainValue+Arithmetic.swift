//
//  UncertainValue+Arithmetic.swift
//  UncertainValueCore
//
//  Arithmetic operations with uncertainty propagation.
//  All operations require explicit NormStrategy - no operators in core.
//

import Foundation

// MARK: - Constant Operations (no norm needed - only one uncertainty source)

extension UncertainValue {
    /// Adds a constant (no norm needed - single error source).
    public func adding(_ constant: Double) -> UncertainValue {
        UncertainValue(value + constant, absoluteError: absoluteError)
    }

    /// Subtracts a constant (no norm needed - single error source).
    public func subtracting(_ constant: Double) -> UncertainValue {
        adding(-constant)
    }

    /// Multiplies by a constant (no norm needed - single error source).
    public func multiplying(by constant: Double) -> UncertainValue {
        UncertainValue(value * constant, absoluteError: absoluteError * abs(constant))
    }

    /// Divides by a constant (no norm needed - single error source).
    /// - Returns: Result, or nil if constant is 0.
    public func dividing(by constant: Double) -> UncertainValue? {
        guard constant != 0 else { return nil }
        return UncertainValue(value / constant, absoluteError: absoluteError / abs(constant))
    }
}
