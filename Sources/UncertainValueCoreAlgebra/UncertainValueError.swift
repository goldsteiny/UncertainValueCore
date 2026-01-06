//
//  UncertainValueError.swift
//  UncertainValueCoreAlgebra
//
//  Error types for invalid mathematical operations.
//

import Foundation

/// Errors thrown by UncertainValue operations.
public enum UncertainValueError: Error, Equatable, Sendable {
    /// Attempted division or reciprocal of zero.
    case divisionByZero

    /// Operation requires a non-empty collection.
    case emptyCollection

    /// Operation requires more elements than provided.
    /// - Parameters:
    ///   - required: Minimum number of elements needed.
    ///   - actual: Number of elements provided.
    case insufficientElements(required: Int, actual: Int)

    /// Operation requires a positive input (e.g., logarithm).
    case nonPositiveInput

    /// Operation requires a positive or zero input (e.g., logarithm).
    case negativeInput

    /// Scale factor is invalid (zero or non-finite).
    case invalidScale

    /// Value is non-finite (NaN or infinity).
    case nonFinite

    /// Value violates domain constraints (e.g., zero for multiplicative types).
    case invalidValue

    /// Multiplicative error must be >= 1.
    case invalidMultiplicativeError
}
