//
//  Signed+Convenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience sign checks.
//

public extension Signed {
    var isPositive: Bool {
        signum == .positive
    }

    var isNegative: Bool {
        signum == .negative
    }
}
