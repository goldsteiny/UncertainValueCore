//
//  MultiplicativeGroups.swift
//  UncertainValueCoreAlgebra
//
//  Multiplicative algebraic hierarchy. Norm-free; uses Swift operators.
//

// MARK: - Monoid

public protocol MultiplicativeMonoid: OneContaining {
    static func * (lhs: Self, rhs: Self) -> Self
}

// MARK: - Monoid with partial inverse (may contain zero)

public protocol MultiplicativeMonoidWithInverse: MultiplicativeMonoid {
    var reciprocal: Result<Self, AlgebraError.DivisionByZero> { get }
}

public extension MultiplicativeMonoidWithInverse {
    func dividing(by other: Self) -> Result<Self, AlgebraError.DivisionByZero> {
        other.reciprocal.map { self * $0 }
    }
}

// MARK: - True group (total inverse)

public protocol MultiplicativeGroup: MultiplicativeMonoid {
    var reciprocal: Self { get }
}

public extension MultiplicativeGroup {
    static func / (lhs: Self, rhs: Self) -> Self {
        lhs * rhs.reciprocal
    }
}

// MARK: - Commutative markers

public protocol CommutativeMultiplicativeMonoid: MultiplicativeMonoid {}
public protocol CommutativeMultiplicativeMonoidWithInverse: MultiplicativeMonoidWithInverse, CommutativeMultiplicativeMonoid {}
public protocol CommutativeMultiplicativeGroup: MultiplicativeGroup, CommutativeMultiplicativeMonoid {}

// MARK: - Productable (opt-in efficient n-ary operation)

public protocol ProductableMonoid: MultiplicativeMonoid {
    static func product(_ values: NonEmptyArray<Self>) -> Self
}

public extension ProductableMonoid {
    @inlinable
    static func * (lhs: Self, rhs: Self) -> Self {
        product(NonEmptyArray(lhs, [rhs]))
    }
}

public protocol ProductableMonoidWithInverse: MultiplicativeMonoidWithInverse, ProductableMonoid {}
