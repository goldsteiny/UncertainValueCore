//
//  MultiplicativeUncertainValue+Operators.swift
//  MultiplicativeUncertainValue
//
//  Convenience operators for scaling by constants.
//

import Foundation
import UncertainValueCore

// MARK: - Mixed Operators (Double, MUV)

extension MultiplicativeUncertainValue {
    public static func * (lhs: Double, rhs: MultiplicativeUncertainValue) -> MultiplicativeUncertainValue? {
        rhs.scaledUp(by: lhs)
    }

    public static func * (lhs: MultiplicativeUncertainValue, rhs: Double) -> MultiplicativeUncertainValue? {
        lhs.scaledUp(by: rhs)
    }

    public static func / (lhs: MultiplicativeUncertainValue, rhs: Double) -> MultiplicativeUncertainValue? {
        lhs.scaledDown(by: rhs)
    }

    public static func / (lhs: Double, rhs: MultiplicativeUncertainValue) -> MultiplicativeUncertainValue? {
        guard lhs != 0 else { return nil }
        return rhs.reciprocal.scaledUp(by: lhs)
    }
}
