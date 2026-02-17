//
//  PartialReciprocalConvenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience helpers for reciprocal/division variants.
//

public extension MultiplicativeMonoidWithPartialReciprocal {
    @inlinable
    var reciprocalOrNil: Self? {
        try? reciprocal().get()
    }

    @inlinable
    func dividedOrNil(by other: Self) -> Self? {
        try? divided(by: other).get()
    }
}
