//
//  ModuleActions.swift
//  UncertainValueCoreAlgebra
//
//  Module actions and linear combination utilities.
//

/// Left scalar action over an additive group.
public protocol LeftModule: AdditiveGroup {
    associatedtype Scalar: Sendable
    func leftScaled(by scalar: Scalar) -> Self
}

/// Right scalar action over an additive group.
public protocol RightModule: AdditiveGroup {
    associatedtype Scalar: Sendable
    func rightScaled(by scalar: Scalar) -> Self
}

public protocol Bimodule: LeftModule, RightModule {}

/// Legacy ergonomic alias.
public typealias Scalable = LeftModule

public extension LeftModule {
    @inlinable
    func scaled(by scalar: Scalar) -> Self {
        leftScaled(by: scalar)
    }

    @inlinable
    static func linearCombination(_ terms: NonEmpty<(Scalar, Self)>) -> Self {
        terms.tail.reduce(terms.head.1.leftScaled(by: terms.head.0)) { partial, next in
            partial + next.1.leftScaled(by: next.0)
        }
    }

    @inlinable
    static func linearCombination(_ terms: [(Scalar, Self)]) -> Self? {
        guard let nonEmpty = NonEmpty(terms) else { return nil }
        return linearCombination(nonEmpty)
    }

    @inlinable
    static func linearCombination(_ a: Scalar, _ x: Self, _ b: Scalar, _ y: Self) -> Self {
        linearCombination(NonEmpty((a, x), [(b, y)]))
    }

    @inlinable
    static func weightedSum(_ terms: NonEmpty<(weight: Scalar, value: Self)>) -> Self {
        let unlabeled = terms.map { ($0.weight, $0.value) }
        return linearCombination(unlabeled)
    }

    @inlinable
    static func weightedSum(_ terms: [(weight: Scalar, value: Self)]) -> Self? {
        guard let nonEmpty = NonEmpty(terms) else { return nil }
        return weightedSum(nonEmpty)
    }
}

public extension LeftModule where Scalar: MultiplicativeGroup {
    @inlinable
    func scaledDown(by scalar: Scalar) -> Self {
        leftScaled(by: scalar.reciprocal)
    }
}

public extension LeftModule where Scalar: MultiplicativeMonoidWithUnits {
    @inlinable
    func scaledDown(by scalar: Scalar) -> Result<Self, DivisionByNonUnitError> {
        guard let unit = scalar.unit else { return .failure(DivisionByNonUnitError()) }
        return .success(leftScaled(by: unit.reciprocal))
    }

    @inlinable
    func scaledDown<Inverse: MultiplicativeInvertible>(by invertible: Inverse) -> Self where Inverse.Element == Scalar {
        leftScaled(by: invertible.reciprocal)
    }
}

public extension RightModule {
    @inlinable
    func scaledRight(by scalar: Scalar) -> Self {
        rightScaled(by: scalar)
    }

    @inlinable
    static func rightLinearCombination(_ terms: NonEmpty<(Self, Scalar)>) -> Self {
        terms.tail.reduce(terms.head.0.rightScaled(by: terms.head.1)) { partial, next in
            partial + next.0.rightScaled(by: next.1)
        }
    }

    @inlinable
    static func rightLinearCombination(_ terms: [(Self, Scalar)]) -> Self? {
        guard let nonEmpty = NonEmpty(terms) else { return nil }
        return rightLinearCombination(nonEmpty)
    }

    @inlinable
    static func rightLinearCombination(_ x: Self, _ a: Scalar, _ y: Self, _ b: Scalar) -> Self {
        rightLinearCombination(NonEmpty((x, a), [(y, b)]))
    }
}

public extension RightModule where Scalar: MultiplicativeGroup {
    @inlinable
    func rightScaledDown(by scalar: Scalar) -> Self {
        rightScaled(by: scalar.reciprocal)
    }
}

public extension RightModule where Scalar: MultiplicativeMonoidWithUnits {
    @inlinable
    func rightScaledDown(by scalar: Scalar) -> Result<Self, DivisionByNonUnitError> {
        guard let unit = scalar.unit else { return .failure(DivisionByNonUnitError()) }
        return .success(rightScaled(by: unit.reciprocal))
    }

    @inlinable
    func rightScaledDown<Inverse: MultiplicativeInvertible>(by invertible: Inverse) -> Self where Inverse.Element == Scalar {
        rightScaled(by: invertible.reciprocal)
    }
}
