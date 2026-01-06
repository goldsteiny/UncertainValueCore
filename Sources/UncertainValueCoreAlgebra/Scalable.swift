//
//  Scalable.swift
//  UncertainValueCoreAlgebra
//
//  Scaling by a scalar factor.
//

import Foundation

/// Types that can be scaled by a scalar factor.
public protocol Scalable: Sendable {
    associatedtype Scalar: BinaryFloatingPoint
    func scaledUp(by scalar: Scalar) -> Self?
    func scaledDown(by scalar: Scalar) -> Self?
}

public extension Scalable {
    /// Default implementation uses reciprocal scaling when the scalar is non-zero.
    func scaledDown(by scalar: Scalar) -> Self? {
        guard scalar != 0 else { return nil }
        return scaledUp(by: 1 / scalar)
    }
}
