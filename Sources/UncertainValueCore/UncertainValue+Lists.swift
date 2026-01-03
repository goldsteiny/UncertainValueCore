//
//  UncertainValue+Lists.swift
//  UncertainValueCore
//
//  Extensions for collections of UncertainValue with explicit norm selection.
//

import Foundation

extension Array where Element == UncertainValue {
    /// Array of central values.
    public var values: [Double] {
        map(\.value)
    }
    
    public var absoluteErrors: [Double] {
        map(\.absoluteError)
    }
    
    public var relativeErrors: [Double] {
        map(\.relativeError)
    }

    /// Sum of all central values.
    public var valuesSum: Double {
        values.reduce(0, +)
    }

    /// Product of all central values.
    public var valuesProduct: Double {
        values.reduce(1, *)
    }

    /// Maximum of the central values.
    public var valuesMax: Double? {
        values.max()
    }

    /// Minimum of the central values.
    public var valuesMin: Double? {
        values.min()
    }

    /// Maximum absolute value of the central values.
    public var valuesAbsMax: Double? {
        values.map { abs($0) }.max()
    }

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

    /// Computes the norm of the absolute error vector using the specified strategy.
    /// - Parameter strategy: The norm strategy to use for combining errors.
    public func absoluteErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(absoluteErrors, using: strategy)
    }

    /// Computes the norm of the relative error vector using the specified strategy.
    /// - Parameter strategy: The norm strategy to use for combining errors.
    public func relativeErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(relativeErrors, using: strategy)
    }
    
    /// Sums all values with error propagation using the specified norm.
    /// - Parameter strategy: The norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty.
    public func sum(using strategy: NormStrategy) -> UncertainValue {
        UncertainValue(valuesSum, absoluteError: absoluteErrorVectorLength(using: strategy))
    }
    
    /// Mea of all values with error propagation using the specified norm.
    /// - Parameter strategy: The norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty.
    public func mean(using strategy: NormStrategy) -> UncertainValue? {
        guard count >= 1 else { return nil }
        return sum(using: strategy).dividing(by: Double(count))!
    }

    /// Multiplies all values with error propagation using the specified norm.
    /// - Parameter strategy: The norm strategy for combining relative errors.
    /// - Returns: Product with combined uncertainty.
    public func product(using strategy: NormStrategy) -> UncertainValue {
        UncertainValue.withRelativeError(valuesProduct, relativeErrorVectorLength(using: strategy))
    }

    /// Computes the L2 norm (Euclidean length) with error propagation.
    /// Formula: sqrt(sum(x_i^2))
    /// Uses normalization by max absolute value for numerical stability.
    /// - Parameter strategy: The norm strategy for combining errors.
    /// - Returns: L2 norm with propagated uncertainty, or nil if computation fails.
    public func norm2(using strategy: NormStrategy) -> UncertainValue? {
        guard !isEmpty else { return .zero }

        guard let scale = valuesAbsMax, scale > 0 else { return .zero }

        let normalizedSquared = compactMap { ($0.dividing(by: scale))?.raised(to: 2) }
        guard normalizedSquared.count == count else { return nil }

        return normalizedSquared.sum(using: strategy).raised(to: 0.5)?.multiplying(by: scale)
    }
}
