//
//  MultiplicativeMonoidWithInverse+Convenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience helpers for multiplicative monoids with inverse.
//

public extension MultiplicativeMonoidWithInverse {
    @inlinable
    var reciprocalOrNil: Self? {
        try? reciprocal.get()
    }

    @inlinable
    func dividingOrNil(by other: Self) -> Self? {
        try? dividing(by: other).get()
    }
}
