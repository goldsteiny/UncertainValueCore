//
//  UncertainValue+Lists.swift
//  UncertainValueCore
//
//  Extensions for collections of UncertainValue with explicit norm selection.
//

import Foundation

extension Array where Element == UncertainValue {
    /// Sum of all central values.
    public var valuesSum: Double {
        map(\.value).reduce(0, +)
    }

    /// Product of all central values.
    public var valuesProduct: Double {
        map(\.value).reduce(1, *)
    }

    /// Computes the norm of the absolute error vector using the specified strategy.
    /// - Parameter strategy: The norm strategy to use for combining errors.
    public func absoluteErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(map(\.absoluteError), using: strategy)
    }

    /// Computes the norm of the relative error vector using the specified strategy.
    /// - Parameter strategy: The norm strategy to use for combining errors.
    public func relativeErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(map(\.relativeError), using: strategy)
    }

    /// Sums all values with error propagation using the specified norm.
    /// - Parameter strategy: The norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty.
    public func sum(using strategy: NormStrategy) -> UncertainValue {
        UncertainValue(valuesSum, absoluteError: absoluteErrorVectorLength(using: strategy))
    }

    /// Multiplies all values with error propagation using the specified norm.
    /// - Parameter strategy: The norm strategy for combining relative errors.
    /// - Returns: Product with combined uncertainty.
    public func product(using strategy: NormStrategy) -> UncertainValue {
        UncertainValue.withRelativeError(valuesProduct, relativeErrorVectorLength(using: strategy))
    }
}
