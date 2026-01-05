//
//  UncertainAdditive.swift
//  UncertainValueCore
//
//  Protocol for types supporting additive operations with uncertainty propagation.
//

import Foundation

// MARK: - UncertainAdditive Protocol

/// Protocol for types that support additive operations with uncertainty propagation.
///
/// Conforming types represent values with associated uncertainty that can be
/// combined additively. The norm strategy determines how independent uncertainties
/// are combined when adding values.
///
/// **Design:** The static `sum(_:using:)` method is the primitive operation.
/// Binary `adding` and `subtracting` are provided as protocol extension defaults
/// that delegate to the list operation. This preserves numerical stability by
/// allowing direct computation over all n values at once.
///
/// - Note: Additive and multiplicative protocols are intentionally separate
///   to avoid over-constraining types.
public protocol UncertainAdditive: Sendable {
    /// The scalar type used for the norm strategy parameter.
    associatedtype Scalar: BinaryFloatingPoint

    /// The additive identity (zero with no uncertainty).
    static var zero: Self { get }

    /// Negates the value (error magnitude unchanged).
    var negative: Self { get }

    /// Sums an array of values using the specified norm strategy for error propagation.
    ///
    /// This is the primitive operation. Conforming types should implement this
    /// with a direct formula that combines all values and errors efficiently.
    ///
    /// - Parameters:
    ///   - values: Array of values to sum.
    ///   - strategy: Norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty. Empty array returns `.zero`.
    static func sum(_ values: [Self], using strategy: NormStrategy) -> Self
}

// MARK: - Default Binary Operations

public extension UncertainAdditive {
    /// Adds another value using the specified norm strategy.
    ///
    /// Default implementation delegates to `Self.sum([self, other], using:)`.
    ///
    /// - Parameters:
    ///   - other: Value to add.
    ///   - strategy: Norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty.
    @inlinable
    func adding(_ other: Self, using strategy: NormStrategy) -> Self {
        Self.sum([self, other], using: strategy)
    }

    /// Subtracts another value using the specified norm strategy.
    /// - Parameters:
    ///   - other: Value to subtract.
    ///   - strategy: Norm strategy for combining absolute errors.
    /// - Returns: Difference with combined uncertainty.
    @inlinable
    func subtracting(_ other: Self, using strategy: NormStrategy) -> Self {
        adding(other.negative, using: strategy)
    }
}

// MARK: - Array Extension

public extension Array where Element: UncertainAdditive {
    /// Sums all elements using the specified norm strategy.
    ///
    /// Forwards to `Element.sum(self, using:)`.
    ///
    /// - Parameter strategy: Norm strategy for combining absolute errors.
    /// - Returns: Sum with combined uncertainty. Empty array returns `.zero`.
    @inlinable
    func sum(using strategy: NormStrategy) -> Element {
        Element.sum(self, using: strategy)
    }
}
