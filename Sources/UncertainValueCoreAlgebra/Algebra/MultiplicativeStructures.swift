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
    static func product(_ values: NonEmpty<Self>) -> Self where Self: MultiplicativeSemigroup {
        values.tail.reduce(values.head, *)
    }

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

/// A multiplicative monoid that can identify its units (invertible elements).
public protocol MultiplicativeMonoidWithUnits: MultiplicativeMonoid {
    var unit: Unit<Self>? { get }
}

public extension MultiplicativeMonoidWithUnits {
    @inlinable
    func reciprocal() -> Result<Self, ReciprocalUnavailableError> {
        guard let unit else { return .failure(ReciprocalUnavailableError()) }
        return .success(unit.reciprocal)
    }

    @inlinable
    func divided(by other: Self) -> Result<Self, DivisionByNonUnitError> {
        guard let denominator = other.unit else { return .failure(DivisionByNonUnitError()) }
        return .success(self * denominator.reciprocal)
    }

    @inlinable
    func divided<Inverse: MultiplicativeInvertible>(by invertible: Inverse) -> Self where Inverse.Element == Self {
        self * invertible.reciprocal
    }
}

// MARK: - Commutative markers

public protocol MultiplicativeCommutativeSemigroup: MultiplicativeSemigroup {}
public protocol MultiplicativeCommutativeMonoid: MultiplicativeMonoid, MultiplicativeCommutativeSemigroup {}
public protocol MultiplicativeCommutativeGroup: MultiplicativeGroup, MultiplicativeCommutativeMonoid {}
public protocol MultiplicativeCommutativeMonoidWithUnits: MultiplicativeMonoidWithUnits, MultiplicativeCommutativeMonoid {}

// MARK: - Pairing protocols for n-ary specialization

public protocol MultiplicativeMonoidProductable: MultiplicativeMonoid, MultiplicativelyProductable {}
public protocol MultiplicativeGroupProductable: MultiplicativeGroup, MultiplicativelyProductable {}
public protocol MultiplicativeMonoidWithUnitsProductable: MultiplicativeMonoidWithUnits, MultiplicativelyProductable {}
