//
//  ProtocolOperators.swift
//  UncertainValueConvenience
//
//  Protocol-based convenience operators that use L2 norm.
//

import UncertainValueCore
import UncertainValueCoreAlgebra

// MARK: - Additive Operators

public func + <T: AdditiveGroup>(lhs: T, rhs: T) -> T where T.Norm == NormStrategy {
    lhs.adding(rhs, using: .l2)
}

public func - <T: AdditiveGroup>(lhs: T, rhs: T) -> T where T.Norm == NormStrategy {
    lhs.subtracting(rhs, using: .l2)
}

// MARK: - Multiplicative Operators

public func * <T: MultiplicativeGroup>(lhs: T, rhs: T) -> T where T.Norm == NormStrategy {
    lhs.multiplying(rhs, using: .l2)
}

/// Division for non-zero types (never optional).
public func / <T: MultiplicativeGroupWithoutZero>(lhs: T, rhs: T) -> T where T.Norm == NormStrategy {
    lhs.dividingAssumingNonZero(by: rhs, using: .l2)
}

/// Division for types that may contain zero.
/// - Throws: `UncertainValueError.divisionByZero` if divisor is zero.
public func / <T: MultiplicativeGroupWithZero>(lhs: T, rhs: T) throws -> T where T.Norm == NormStrategy {
    try lhs.dividing(by: rhs, using: .l2)
}
