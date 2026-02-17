//
//  AdditiveGroups.swift
//  UncertainValueCoreAlgebra
//
//  Additive algebraic hierarchy. Norm-free; uses Swift operators.
//

// MARK: - Monoid

public protocol AdditiveMonoid: ZeroContaining {
    static func + (lhs: Self, rhs: Self) -> Self
}

public extension AdditiveMonoid {
    static func sum(_ values: NonEmptyArray<Self>) -> Self {
        values.tail.reduce(values.head, +)
    }
}

// MARK: - Group (monoid + inverse)

public protocol AdditiveGroup: AdditiveMonoid {
    prefix static func - (operand: Self) -> Self
}

public extension AdditiveGroup {
    static func - (lhs: Self, rhs: Self) -> Self {
        lhs + (-rhs)
    }
}

// MARK: - Commutative markers

public protocol CommutativeAdditiveMonoid: AdditiveMonoid {}
public protocol CommutativeAdditiveGroup: AdditiveGroup, CommutativeAdditiveMonoid {}

// MARK: - Summable (opt-in efficient n-ary operation)

public protocol SummableMonoid: AdditiveMonoid {
    static func sum(_ values: NonEmptyArray<Self>) -> Self
}

public extension SummableMonoid {
    @inlinable
    static func + (lhs: Self, rhs: Self) -> Self {
        sum(NonEmptyArray(lhs, [rhs]))
    }
}

public protocol SummableGroup: AdditiveGroup, SummableMonoid {}
