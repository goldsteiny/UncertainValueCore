//
//  UncertainValue+Lists.swift
//  UncertainValueCore
//
//  Extensions for collections of UncertainValue with explicit norm selection.
//

import Foundation
import UncertainValueCoreAlgebra

// MARK: - Array Helpers For Min/Max/AbsMax

extension Array where Element == UncertainValue {
    /// Returns the element with the maximum value.
    /// If multiple elements share the maximum value, returns the one with the largest error.
    public var max: UncertainValue? {
        self.max { a, b in
            if a.value != b.value {
                return a.value < b.value
            }
            return a.absoluteError < b.absoluteError
        }
    }
    
    /// Returns the element with the largest absolute value.
    /// If multiple elements share the same absolute value, returns the one with the largest error.
    public var absMax: UncertainValue? {
        return absolutes.max
    }
    
    /// Returns the element with the minimum value.
    /// If multiple elements share the minimum value, returns the one with the largest error.
    public var min: UncertainValue? {
        self.min { a, b in
            if a.value != b.value {
                return a.value < b.value
            }
            return a.absoluteError > b.absoluteError
        }
    }
}

// MARK: Array Helper For Very Simple Array Statistics

extension Array where Element == UncertainValue {

    /// Computes the L2 norm (Euclidean length) with error propagation.
    /// Formula: sqrt(sum(x_i^2))
    /// Uses normalization by max absolute value for numerical stability.
    /// - Parameter strategy: The norm strategy for combining errors.
    /// - Returns: L2 norm with propagated uncertainty, or nil if computation fails.
    public func norm2(using strategy: NormStrategy) -> UncertainValue? {
        guard !isEmpty else { return .zero }

        guard let scale = values.absMax, scale > 0 else { return .zero }

        let normalizedSquared = compactMap { ($0.dividing(by: scale))?.raised(to: 2) }
        guard normalizedSquared.count == count else { return nil }

        return normalizedSquared.sum(using: strategy).raised(to: 0.5)?.multiplying(by: scale)
    }
}
