//
//  AdditiveGroups.swift
//  UncertainValueCoreAlgebra
//
//  Additive group protocols with norm-aware operations.
//

import Foundation

/// Additive group with a norm-aware binary operation.
public protocol AdditiveGroup: ZeroContaining {
    associatedtype Norm
    func adding(_ other: Self, using strategy: Norm) -> Self
    var negative: Self { get }
}

public extension AdditiveGroup {
    /// Subtracts another value using the specified norm strategy.
    @inlinable
    func subtracting(_ other: Self, using strategy: Norm) -> Self {
        adding(other.negative, using: strategy)
    }
}

public extension AdditiveGroup where Self: Scalable {
    /// Default negation using scalar scaling.
    var negative: Self {
        guard let value = scaledUp(by: -1) else {
            preconditionFailure("Scaling by -1 must succeed for additive groups.")
        }
        return value
    }
}

/// Commutative additive group with a list-based sum primitive.
public protocol CommutativeAdditiveGroup: AdditiveGroup {
    static func sum(_ values: [Self], using strategy: Norm) -> Self
}

public extension CommutativeAdditiveGroup {
    /// Default binary addition delegates to the list-based primitive.
    @inlinable
    func adding(_ other: Self, using strategy: Norm) -> Self {
        Self.sum([self, other], using: strategy)
    }
}

public extension Array where Element: CommutativeAdditiveGroup {
    /// Sums all elements using the specified norm strategy.
    @inlinable
    func sum(using strategy: Element.Norm) -> Element {
        Element.sum(self, using: strategy)
    }
}
