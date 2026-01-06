//
//  UncertainMultiplicative.swift
//  UncertainValueCore
//
//  Protocols for multiplicative operations with uncertainty propagation.
//

import Foundation

// MARK: - UncertainMultiplicative Protocol

/// Protocol for types that support multiplicative operations with uncertainty propagation.
///
/// Conforming types represent values with associated uncertainty that can be
/// combined multiplicatively. The norm strategy determines how independent
/// uncertainties are combined when multiplying values.
///
/// **Design:** The static `product(_:using:)` method is the primitive operation.
/// Binary `multiplying` is provided as a protocol extension default that
/// delegates to the list operation. This preserves numerical stability by
/// allowing direct computation over all n values at once.
public protocol UncertainMultiplicative: Sendable {
    /// The scalar type used for exponents and the norm strategy parameter.
    associatedtype Scalar: BinaryFloatingPoint

    /// The multiplicative identity (one with no uncertainty).
    static var one: Self { get }

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
}

// MARK: - InvertibleUncertainMultiplicative Protocol

/// Protocol for multiplicative types that can be inverted (reciprocal/division).
///
/// Types that can represent zero should throw `UncertainValueError.divisionByZero`
/// when the reciprocal or division is undefined.
public protocol InvertibleUncertainMultiplicative: UncertainMultiplicative {
    /// Computes the reciprocal (1/x) with error propagation.
    /// - Returns: Reciprocal with propagated error.
    /// - Throws: `UncertainValueError.divisionByZero` when the value is zero.
    var reciprocal: Self { get throws }
}

public extension InvertibleUncertainMultiplicative {
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

    /// Optional convenience for reciprocal.
    @inlinable
    var reciprocalOrNil: Self? {
        try? reciprocal
    }

    /// Optional convenience for division.
    @inlinable
    func dividingOrNil(by other: Self, using strategy: NormStrategy) -> Self? {
        try? dividing(by: other, using: strategy)
    }
}

// MARK: - NonZeroInvertibleUncertainMultiplicative Protocol

/// Protocol for multiplicative types that cannot represent zero.
///
/// These types can provide non-throwing inversion APIs while still conforming
/// to the throwing `InvertibleUncertainMultiplicative` requirements.
public protocol NonZeroInvertibleUncertainMultiplicative: InvertibleUncertainMultiplicative {
    /// Computes the reciprocal (1/x) assuming the value is non-zero.
    var reciprocalAssumingNonZero: Self { get }
}

public extension NonZeroInvertibleUncertainMultiplicative {
    /// Default throwing reciprocal implementation for non-zero types.
    @inlinable
    var reciprocal: Self {
        get throws {
            reciprocalAssumingNonZero
        }
    }

    /// Non-throwing division for non-zero types.
    @inlinable
    func dividingAssumingNonZero(by other: Self, using strategy: NormStrategy) -> Self {
        multiplying(other.reciprocalAssumingNonZero, using: strategy)
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
