//
//  NormAwareAlgebra.swift
//  UncertainValueSupport
//
//  Uncertainty-specific algebra protocols that require an explicit norm strategy.
//

import AlgebraDomainLanguage

public typealias SignMagnitudeProviding = AbsoluteValueDecomposable

public protocol DiscreteRaisable: Sendable {
    func raised(to power: Int) throws -> Self
}

public protocol SignedRaisable: DiscreteRaisable, Sendable {
    associatedtype Scalar: BinaryFloatingPoint
    func raised(to power: Scalar) throws -> Self
}

public extension SignedRaisable where Self: SignMagnitudeProviding, Scalar == Double {
    @inlinable
    func raised(to power: Int) throws -> Self {
        let resultAbsolute = try absolute.raised(to: Double(power))

        switch signum {
        case .negative:
            return power.isMultiple(of: 2) ? resultAbsolute : resultAbsolute.flippedSign
        default:
            return resultAbsolute
        }
    }
}

public protocol CommutativeAdditiveGroup: Zero, Sendable {
    associatedtype Norm: Sendable
    static func sum(_ values: [Self], using strategy: Norm) -> Self
    var negative: Self { get }
}

public extension CommutativeAdditiveGroup {
    @inlinable
    func adding(_ other: Self, using strategy: Norm) -> Self {
        Self.sum([self, other], using: strategy)
    }

    @inlinable
    func subtracting(_ other: Self, using strategy: Norm) -> Self {
        adding(other.negative, using: strategy)
    }
}

public extension Array where Element: CommutativeAdditiveGroup {
    @inlinable
    func sum(using strategy: Element.Norm) -> Element {
        Element.sum(self, using: strategy)
    }
}

public protocol CommutativeMultiplicativeGroup: One, Sendable {
    associatedtype Norm: Sendable
    static func product(_ values: [Self], using strategy: Norm) -> Self
}

public extension CommutativeMultiplicativeGroup {
    @inlinable
    func multiplying(_ other: Self, using strategy: Norm) -> Self {
        Self.product([self, other], using: strategy)
    }
}

public extension Array where Element: CommutativeMultiplicativeGroup {
    @inlinable
    func product(using strategy: Element.Norm) -> Element {
        Element.product(self, using: strategy)
    }
}

public protocol MultiplicativeGroupWithZero: CommutativeMultiplicativeGroup {
    var reciprocal: Self { get throws }
}

public extension MultiplicativeGroupWithZero {
    @inlinable
    func dividing(by other: Self, using strategy: Norm) throws -> Self {
        try multiplying(other.reciprocal, using: strategy)
    }
}

public protocol MultiplicativeGroupWithoutZero: MultiplicativeGroupWithZero {
    var reciprocalAssumingNonZero: Self { get }
}

public extension MultiplicativeGroupWithoutZero {
    @inlinable
    var reciprocal: Self {
        get throws {
            reciprocalAssumingNonZero
        }
    }

    @inlinable
    func dividingAssumingNonZero(by other: Self, using strategy: Norm) -> Self {
        multiplying(other.reciprocalAssumingNonZero, using: strategy)
    }
}

public protocol CommutativeMultiplicativeGroupWithZero: MultiplicativeGroupWithZero {}
public protocol CommutativeMultiplicativeGroupWithoutZero: MultiplicativeGroupWithoutZero {}

public protocol CommutativeAlgebraWithZero:
    CommutativeAdditiveGroup,
    CommutativeMultiplicativeGroupWithZero
{}

public protocol CommutativeAlgebraWithoutZero:
    CommutativeAdditiveGroup,
    CommutativeMultiplicativeGroupWithoutZero
{}
