//
//  UncertainValue+Arithmetic.swift
//  UncertainValueCore
//
//  Arithmetic operations with uncertainty propagation.
//  All operations require explicit NormStrategy - no operators in core.
//

import Foundation

// MARK: - Single-Value Operations (no norm needed)

extension UncertainValue {
    /// Raises value to a real power with error propagation.
    /// - Parameter p: The exponent.
    /// - Returns: Result with propagated error, or nil if base <= 0 or non-finite.
    public func raised(to p: Double) -> UncertainValue? {
        guard value > 0 else { return nil }
        let newValue = pow(value, p)
        guard newValue.isFinite else { return nil }
        
        let newRelError = abs(p) * relativeError
        guard newRelError.isFinite else { return nil }
        
        return UncertainValue.withRelativeError(newValue, newRelError)
    }
    
    /// Raises value to an integer power (allows negative bases).
    /// - Parameter n: Integer exponent.
    /// - Returns: Result with propagated error, or nil if invalid (e.g., 0^negative, non-finite).
    public func raised(to n: Int) -> UncertainValue? {
        if value == 0 {
            guard absoluteError == 0, n > 0 else { return nil }
            return UncertainValue(0.0, absoluteError: 0.0)
        }
        
        let newValue = pow(value, Double(n))
        guard newValue.isFinite else { return nil }
        
        let newRelError = abs(Double(n)) * relativeError
        guard newRelError.isFinite else { return nil }
        
        return UncertainValue.withRelativeError(newValue, newRelError)
    }

    /// Negates the value (error unchanged).
    public var negative: UncertainValue {
        UncertainValue(-value, absoluteError: absoluteError)
    }

    /// Computes reciprocal (1/x) with error propagation.
    /// - Returns: Reciprocal with propagated error, or nil if value is 0.
    /// - Formula: relError(1/x) = relError(x)
    public var reciprocal: UncertainValue? {
        guard value != 0 else { return nil }
        return UncertainValue.withRelativeError(1 / value, relativeError)
    }
}

// MARK: - Norm-Aware Binary Operations (UncertainValue, UncertainValue)

extension UncertainValue {
    /// Adds another UncertainValue using the specified norm strategy.
    /// - Parameters:
    ///   - other: Value to add.
    ///   - strategy: Norm strategy for combining absolute errors.
    public func adding(_ other: UncertainValue, using strategy: NormStrategy) -> UncertainValue {
        [self, other].sum(using: strategy)
    }

    /// Subtracts another UncertainValue using the specified norm strategy.
    /// - Parameters:
    ///   - other: Value to subtract.
    ///   - strategy: Norm strategy for combining absolute errors.
    public func subtracting(_ other: UncertainValue, using strategy: NormStrategy) -> UncertainValue {
        adding(other.negative, using: strategy)
    }

    /// Multiplies by another UncertainValue using the specified norm strategy.
    /// - Parameters:
    ///   - other: Value to multiply by.
    ///   - strategy: Norm strategy for combining relative errors.
    public func multiplying(_ other: UncertainValue, using strategy: NormStrategy) -> UncertainValue {
        [self, other].product(using: strategy)
    }

    /// Divides by another UncertainValue using the specified norm strategy.
    /// - Parameters:
    ///   - other: Divisor value.
    ///   - strategy: Norm strategy for combining relative errors.
    /// - Returns: Result, or nil if divisor is 0.
    public func dividing(by other: UncertainValue, using strategy: NormStrategy) -> UncertainValue? {
        return other.reciprocal?.multiplying(self, using: strategy)
    }
}

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
