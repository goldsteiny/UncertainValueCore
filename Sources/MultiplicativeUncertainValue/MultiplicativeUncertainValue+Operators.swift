//
//  MultiplicativeUncertainValue+Operators.swift
//  MultiplicativeUncertainValue
//
//  Convenience operators using L2 norm.
//

import Foundation
import UncertainValueCore

// MARK: - Binary Operators (MUV, MUV)

extension MultiplicativeUncertainValue {
    public static func * (lhs: MultiplicativeUncertainValue, rhs: MultiplicativeUncertainValue) -> MultiplicativeUncertainValue {
        lhs.multiplying(rhs, using: .l2)
    }

    public static func / (lhs: MultiplicativeUncertainValue, rhs: MultiplicativeUncertainValue) -> MultiplicativeUncertainValue {
        lhs.dividing(by: rhs, using: .l2)
    }
}

// MARK: - Mixed Operators (Double, MUV)

extension MultiplicativeUncertainValue {
    public static func * (lhs: Double, rhs: MultiplicativeUncertainValue) -> MultiplicativeUncertainValue {
        rhs.scaledUp(by: lhs)
    }

    public static func * (lhs: MultiplicativeUncertainValue, rhs: Double) -> MultiplicativeUncertainValue {
        lhs.scaledUp(by: rhs)
    }

    public static func / (lhs: MultiplicativeUncertainValue, rhs: Double) -> MultiplicativeUncertainValue {
        lhs.scaledDown(by: rhs)
    }

    public static func / (lhs: Double, rhs: MultiplicativeUncertainValue) -> MultiplicativeUncertainValue {
        precondition(lhs != 0, "Cannot create zero: MultiplicativeUncertainValue cannot represent 0")
        return rhs.reciprocal.scaledUp(by: lhs)
    }
}
