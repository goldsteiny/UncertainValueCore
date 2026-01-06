//
//  MultiplicativeGroups.swift
//  UncertainValueCoreAlgebra
//
//  Multiplicative group protocols with norm-aware operations.
//

import Foundation

/// Multiplicative group with a norm-aware binary operation.
public protocol MultiplicativeGroup: OneContaining {
    associatedtype Norm
    func multiplying(_ other: Self, using strategy: Norm) -> Self
}

/// Commutative multiplicative group with a list-based product primitive.
public protocol CommutativeMultiplicativeGroup: MultiplicativeGroup {
    static func product(_ values: [Self], using strategy: Norm) -> Self
}

public extension CommutativeMultiplicativeGroup {
    /// Default binary multiplication delegates to the list-based primitive.
    @inlinable
    func multiplying(_ other: Self, using strategy: Norm) -> Self {
        Self.product([self, other], using: strategy)
    }
}

/// Multiplicative group that can contain zero (reciprocal may throw).
public protocol MultiplicativeGroupWithZero: MultiplicativeGroup {
    var reciprocal: Self { get throws }
}

public extension MultiplicativeGroupWithZero {
    /// Divides by another value using the specified norm strategy.
    @inlinable
    func dividing(by other: Self, using strategy: Norm) throws -> Self {
        try multiplying(other.reciprocal, using: strategy)
    }

    /// Optional convenience for reciprocal.
    @inlinable
    var reciprocalOrNil: Self? {
        try? reciprocal
    }

    /// Optional convenience for division.
    @inlinable
    func dividingOrNil(by other: Self, using strategy: Norm) -> Self? {
        try? dividing(by: other, using: strategy)
    }
}

/// Multiplicative group that cannot represent zero.
public protocol MultiplicativeGroupWithoutZero: MultiplicativeGroupWithZero {
    var reciprocalAssumingNonZero: Self { get }
}

public extension MultiplicativeGroupWithoutZero {
    /// Default throwing reciprocal implementation for non-zero types.
    @inlinable
    var reciprocal: Self {
        get throws {
            reciprocalAssumingNonZero
        }
    }

    /// Non-throwing division for non-zero types.
    @inlinable
    func dividingAssumingNonZero(by other: Self, using strategy: Norm) -> Self {
        multiplying(other.reciprocalAssumingNonZero, using: strategy)
    }
}

/// Commutative multiplicative group that can contain zero.
public protocol CommutativeMultiplicativeGroupWithZero: CommutativeMultiplicativeGroup, MultiplicativeGroupWithZero {}

/// Commutative multiplicative group that cannot represent zero.
public protocol CommutativeMultiplicativeGroupWithoutZero: CommutativeMultiplicativeGroup, MultiplicativeGroupWithoutZero {}

public extension Array where Element: CommutativeMultiplicativeGroup {
    /// Computes the product of all elements using the specified norm strategy.
    @inlinable
    func product(using strategy: Element.Norm) -> Element {
        Element.product(self, using: strategy)
    }
}
