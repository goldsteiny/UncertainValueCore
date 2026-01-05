//
//  UncertainValue+Operators.swift
//  UncertainValueConvenience
//
//  Convenience operators that use L2 norm (standard Gaussian error propagation).
//  Import this module for ergonomic operator syntax when L2 is acceptable.
//
//  For explicit norm control, use the core methods:
//    - a.adding(b, using: strategy)
//    - a.multiplying(b, using: strategy)
//    - etc.
//

import UncertainValueCore

// MARK: - Binary Operators (UncertainValue, UncertainValue)

extension UncertainValue {
    public static func + (lhs: UncertainValue, rhs: UncertainValue) -> UncertainValue {
        lhs.adding(rhs, using: .l2)
    }

    public static func - (lhs: UncertainValue, rhs: UncertainValue) -> UncertainValue {
        lhs.subtracting(rhs, using: .l2)
    }

    public static func * (lhs: UncertainValue, rhs: UncertainValue) -> UncertainValue {
        lhs.multiplying(rhs, using: .l2)
    }

    public static func / (lhs: UncertainValue, rhs: UncertainValue) -> UncertainValue? {
        try? lhs.dividing(by: rhs, using: .l2)
    }
}

// MARK: - Mixed Operators (Double, UncertainValue)

extension UncertainValue {
    public static func + (lhs: Double, rhs: UncertainValue) -> UncertainValue {
        rhs.adding(lhs)
    }

    public static func + (lhs: UncertainValue, rhs: Double) -> UncertainValue {
        lhs.adding(rhs)
    }

    public static func - (lhs: Double, rhs: UncertainValue) -> UncertainValue {
        rhs.negative.adding(lhs)
    }

    public static func - (lhs: UncertainValue, rhs: Double) -> UncertainValue {
        lhs.subtracting(rhs)
    }

    public static func * (lhs: Double, rhs: UncertainValue) -> UncertainValue {
        rhs.multiplying(by: lhs)
    }

    public static func * (lhs: UncertainValue, rhs: Double) -> UncertainValue {
        lhs.multiplying(by: rhs)
    }

    public static func / (lhs: Double, rhs: UncertainValue) -> UncertainValue? {
        try? rhs.reciprocal.multiplying(by: lhs)
    }

    public static func / (lhs: UncertainValue, rhs: Double) -> UncertainValue? {
        lhs.dividing(by: rhs)
    }
}
