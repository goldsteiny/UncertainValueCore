//
//  MultiplicativeStructures.swift
//  UncertainValueCoreAlgebra
//
//  Canonical multiplicative algebra hierarchy.
//

// MARK: - Binary and n-ary multiplicative primitives

public protocol MultiplicativeSemigroup: Sendable {
    static func * (lhs: Self, rhs: Self) -> Self
}

public protocol MultiplicativelyProductable: Sendable {
    static func product(_ values: NonEmpty<Self>) -> Self
}

public extension MultiplicativeSemigroup {
    @inlinable
    static func product(_ values: NonEmpty<Self>) -> Self {
        values.tail.reduce(values.head, *)
    }
}

public extension MultiplicativelyProductable {
    @inlinable
    static func * (lhs: Self, rhs: Self) -> Self {
        product(NonEmpty(lhs, [rhs]))
    }
}

// MARK: - Canonical multiplicative tower

/// Explicitly states that multiplicative semigroup and n-ary product coexist.
public protocol MultiplicativeSemigroupProductable: MultiplicativeSemigroup, MultiplicativelyProductable {}

public protocol MultiplicativeMonoid: MultiplicativeSemigroupProductable, One {}

/// Total reciprocal (for types that exclude zero from the carrier set).
public protocol MultiplicativeGroup: MultiplicativeMonoid {
    var reciprocal: Self { get }
}

public extension MultiplicativeGroup {
    @inlinable
    static func / (lhs: Self, rhs: Self) -> Self {
        lhs * rhs.reciprocal
    }
}

/// Partial reciprocal (typically undefined at zero).
public protocol MultiplicativeMonoidWithPartialReciprocal: MultiplicativeMonoid, Zero {
    func reciprocal() -> Result<Self, ReciprocalOfZeroError>
}

public extension MultiplicativeMonoidWithPartialReciprocal {
    @inlinable
    func divided(by other: Self) -> Result<Self, DivisionByZeroError> {
        other.reciprocal()
            .mapError { DivisionByZeroError($0.context) }
            .map { self * $0 }
    }

    @inlinable
    func divided(by knownNonZero: NonZero<Self>) -> Self {
        switch knownNonZero.value.reciprocal() {
        case .success(let reciprocal):
            return self * reciprocal
        case .failure:
            preconditionFailure("NonZero invariant broken: reciprocal failed for non-zero denominator.")
        }
    }
}

// MARK: - Commutative markers

public protocol MultiplicativeCommutativeSemigroup: MultiplicativeSemigroup {}
public protocol MultiplicativeCommutativeMonoid: MultiplicativeMonoid, MultiplicativeCommutativeSemigroup {}
public protocol MultiplicativeCommutativeGroup: MultiplicativeGroup, MultiplicativeCommutativeMonoid {}
public protocol MultiplicativeCommutativeMonoidWithPartialReciprocal: MultiplicativeMonoidWithPartialReciprocal, MultiplicativeCommutativeMonoid {}

// MARK: - Pairing protocols for n-ary specialization

public protocol MultiplicativeMonoidProductable: MultiplicativeMonoid, MultiplicativelyProductable {}
public protocol MultiplicativeGroupProductable: MultiplicativeGroup, MultiplicativelyProductable {}
public protocol MultiplicativeMonoidWithPartialReciprocalProductable: MultiplicativeMonoidWithPartialReciprocal, MultiplicativelyProductable {}
