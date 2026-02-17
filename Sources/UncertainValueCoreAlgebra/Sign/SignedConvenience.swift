//
//  SignedConvenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience sign checks.
//

public extension Signed {
    @inlinable
    var isPositive: Bool {
        signum == .positive
    }

    @inlinable
    var isNegative: Bool {
        signum == .negative
    }

    @inlinable
    var isSignZero: Bool {
        signum == .zero
    }
}
