//
//  BoundsProviding+ErrorProviding.swift
//  UncertainValueCore
//
//  Created by Yaron Goldstein on 2026-01-07.
//

// MARK: - Default Implementation for AbsoluteErrorProviding

public extension BoundsProviding where Self: AbsoluteErrorProviding {
    /// Lower bound using additive error: `value - absoluteError`
    var lowerBound: Scalar {
        value - absoluteError
    }
    
    /// Upper bound using additive error: `value + absoluteError`
    var upperBound: Scalar {
        value + absoluteError
    }
    
    /// Confidence interval: `[value - absoluteError, value + absoluteError]`
    var bounds: ClosedRange<Scalar> {
        lowerBound...upperBound
    }
}

// MARK: - Default Implementation for MultiplicativeErrorProviding

public extension BoundsProviding where Self: MultiplicativeErrorProviding {
    /// Lower bound using multiplicative error.
    ///
    /// Uses `min` to handle negative values correctly:
    /// - Positive values: `value / multiplicativeError` (smaller)
    /// - Negative values: `value * multiplicativeError` (more negative)
    var lowerBound: Scalar {
        min(value * multiplicativeError, value / multiplicativeError)
    }
    
    /// Upper bound using multiplicative error.
    ///
    /// Uses `max` to handle negative values correctly:
    /// - Positive values: `value * multiplicativeError` (larger)
    /// - Negative values: `value / multiplicativeError` (less negative)
    var upperBound: Scalar {
        max(value * multiplicativeError, value / multiplicativeError)
    }
    
    /// Confidence interval: `[min(v*m, v/m), max(v*m, v/m)]`
    /// where `v = value` and `m = multiplicativeError`
    var bounds: ClosedRange<Scalar> {
        lowerBound...upperBound
    }
}
