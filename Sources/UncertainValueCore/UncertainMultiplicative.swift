//
//  UncertainMultiplicative.swift
//  UncertainValueCore
//
//  Protocol for types supporting multiplicative operations with uncertainty propagation.
//

import Foundation

// MARK: - UncertainMultiplicative Protocol

/// Protocol for types that support multiplicative operations with uncertainty propagation.
///
/// Conforming types represent values with associated uncertainty that can be
/// combined multiplicatively. The norm strategy determines how independent uncertainties
/// are combined when multiplying values.
///
/// **Design:** The static `product(_:using:)` method is the primitive operation.
/// Binary `multiplying` and `dividing` are provided as protocol extension defaults
/// that delegate to the list operation. This preserves numerical stability by
/// allowing direct computation over all n values at once.
///
/// - Note: Additive and multiplicative protocols are intentionally separate
///   to avoid over-constraining types.
public protocol UncertainMultiplicative: Sendable {
    /// The scalar type used for exponents and the norm strategy parameter.
    associatedtype Scalar: BinaryFloatingPoint

    /// The multiplicative identity (one with no uncertainty).
    static var one: Self { get }

    /// Computes the reciprocal (1/x) with error propagation.
    /// - Returns: Reciprocal with propagated error.
    /// - Throws: `UncertainValueError.divisionByZero` when the value is zero.
    var reciprocal: Self { get throws }

    /// Raises the value to a scalar power with error propagation.
    /// - Parameter power: The exponent.
    /// - Returns: Result with propagated error, or nil if the operation is undefined.
    func raised(to power: Scalar) -> Self?

    /// Computes the product of an array of values using the specified norm strategy.
    ///
    /// This is the primitive operation. Conforming types should implement this
    /// with a direct formula that combines all values and errors efficiently.
    ///
    /// - Parameters:
    ///   - values: Array of values to multiply.
    ///   - strategy: Norm strategy for combining relative errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    static func product(_ values: [Self], using strategy: NormStrategy) -> Self
}

// MARK: - Default Binary Operations

public extension UncertainMultiplicative {
    /// Multiplies by another value using the specified norm strategy.
    ///
    /// Default implementation delegates to `Self.product([self, other], using:)`.
    ///
    /// - Parameters:
    ///   - other: Value to multiply by.
    ///   - strategy: Norm strategy for combining relative errors.
    /// - Returns: Product with combined uncertainty.
    @inlinable
    func multiplying(_ other: Self, using strategy: NormStrategy) -> Self {
        Self.product([self, other], using: strategy)
    }

    /// Divides by another value using the specified norm strategy.
    /// - Parameters:
    ///   - other: Divisor value.
    ///   - strategy: Norm strategy for combining relative errors.
    /// - Returns: Quotient with combined uncertainty.
    /// - Throws: `UncertainValueError.divisionByZero` when the divisor is zero.
    @inlinable
    func dividing(by other: Self, using strategy: NormStrategy) throws -> Self {
        try multiplying(other.reciprocal, using: strategy)
    }
}

// MARK: - Array Extension

public extension Array where Element: UncertainMultiplicative {
    /// Computes the product of all elements using the specified norm strategy.
    ///
    /// Forwards to `Element.product(self, using:)`.
    ///
    /// - Parameter strategy: Norm strategy for combining relative errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    @inlinable
    func product(using strategy: NormStrategy) -> Element {
        Element.product(self, using: strategy)
    }
}
