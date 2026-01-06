//
//  UncertainValue+Operators.swift
//  UncertainValueConvenience
//
//  Convenience operators for scaling UncertainValue by constants.
//  Same-type operators are defined on protocols in `ProtocolOperators.swift`
//  and use L2 norm (standard Gaussian error propagation).
//

import UncertainValueCore

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
        rhs.reciprocalOrNil?.multiplying(by: lhs)
    }

    public static func / (lhs: UncertainValue, rhs: Double) -> UncertainValue? {
        lhs.dividing(by: rhs)
    }
}
