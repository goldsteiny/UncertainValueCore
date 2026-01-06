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
        // Safe: -1 is always a valid scale factor (non-zero, finite)
        try! scaledUp(by: -1)
    }
}

public extension AdditiveGroup where Self: SignumProvidingBase {
    /// Default sign flip for additive groups uses negation.
    @inlinable
    var flippedSign: Self {
        negative
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
