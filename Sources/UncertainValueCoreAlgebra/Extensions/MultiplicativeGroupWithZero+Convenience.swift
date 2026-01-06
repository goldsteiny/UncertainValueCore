//
//  MultiplicativeGroupWithZero+Convenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience helpers for multiplicative groups with zero.
//

import Foundation

public extension MultiplicativeGroupWithZero {
    /// Optional convenience for reciprocal.
    @inlinable
    var reciprocalOrNil: Self? {
        try? reciprocal
    }

    /// Optional convenience for division.
    @inlinable
    func dividingOrNil(by other: Self, using strategy: Norm) -> Self? {
        try? dividing(by: other, using: strategy)
    }
}
