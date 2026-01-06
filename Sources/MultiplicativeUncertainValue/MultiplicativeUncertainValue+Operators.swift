//
//  MultiplicativeUncertainValue+Operators.swift
//  MultiplicativeUncertainValue
//
//  Convenience operators for scaling by constants.
//

import Foundation
import UncertainValueCore
import UncertainValueCoreAlgebra

// MARK: - Mixed Operators (Double, MUV)

extension MultiplicativeUncertainValue {
    public static func * (lhs: Double, rhs: MultiplicativeUncertainValue) throws -> MultiplicativeUncertainValue {
        try rhs.scaledUp(by: lhs)
    }

    public static func * (lhs: MultiplicativeUncertainValue, rhs: Double) throws -> MultiplicativeUncertainValue {
        try lhs.scaledUp(by: rhs)
    }

    public static func / (lhs: MultiplicativeUncertainValue, rhs: Double) throws -> MultiplicativeUncertainValue {
        try lhs.scaledDown(by: rhs)
    }

    public static func / (lhs: Double, rhs: MultiplicativeUncertainValue) throws -> MultiplicativeUncertainValue {
        guard lhs != 0, lhs.isFinite else { throw UncertainValueError.invalidScale }
        return try rhs.reciprocal.scaledUp(by: lhs)
    }
}
