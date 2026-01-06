//
//  SignumProvidingBase+Convenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience sign checks.
//

import Foundation

public extension SignumProvidingBase {
    var isPositive: Bool {
        signum == .positive
    }

    var isNegative: Bool {
        signum == .negative
    }

    var isZero: Bool {
        signum == .zero
    }
}
