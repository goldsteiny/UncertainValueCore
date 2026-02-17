//
//  AdditiveStructures.swift
//  UncertainValueCoreAlgebra
//
//  Canonical additive algebra hierarchy.
//

// MARK: - Binary and n-ary additive primitives

public protocol AdditiveSemigroup: Sendable {
    static func + (lhs: Self, rhs: Self) -> Self
}

public protocol AdditivelySummable: Sendable {
    static func sum(_ values: NonEmpty<Self>) -> Self
}

public extension AdditiveSemigroup {
    @inlinable
    static func directSum(_ lhs: Self, _ rhs: Self) -> Self {
        lhs + rhs
    }

    @inlinable
    static func sum(_ values: NonEmpty<Self>) -> Self {
        values.tail.reduce(values.head, +)
    }

    @inlinable
    static func sum(_ first: Self, _ second: Self, _ rest: Self...) -> Self {
        sum(NonEmpty(first, [second] + rest))
    }
}

public extension AdditivelySummable {
    @inlinable
    static func sum(_ values: NonEmpty<Self>) -> Self where Self: AdditiveSemigroup {
        values.tail.reduce(values.head, +)
    }

    @inlinable
    static func + (lhs: Self, rhs: Self) -> Self {
        sum(NonEmpty(lhs, [rhs]))
    }
}

// MARK: - Canonical additive tower

/// Explicitly states that additive semigroup and n-ary summation coexist.
public protocol AdditiveSemigroupSummable: AdditiveSemigroup, AdditivelySummable {}

public protocol AdditiveMonoid: AdditiveSemigroupSummable, Zero {}

public protocol AdditiveGroup: AdditiveMonoid {
    prefix static func - (operand: Self) -> Self
}

public extension AdditiveGroup where Self: SignedNumeric {
    @inlinable
    static prefix func - (operand: Self) -> Self {
        var value = operand
        value.negate()
        return value
    }
}

public extension AdditiveGroup {
    @inlinable
    static func - (lhs: Self, rhs: Self) -> Self {
        lhs + (-rhs)
    }
}

/// Commutative additive group.
public protocol AdditiveAbelianGroup: AdditiveGroup {}

// MARK: - Pairing protocols for n-ary specialization

public protocol AdditiveMonoidSummable: AdditiveMonoid, AdditivelySummable {}
public protocol AdditiveGroupSummable: AdditiveGroup, AdditivelySummable {}
public protocol AdditiveAbelianGroupSummable: AdditiveAbelianGroup, AdditivelySummable {}
