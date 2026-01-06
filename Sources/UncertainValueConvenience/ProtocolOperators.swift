//
//  ProtocolOperators.swift
//  UncertainValueConvenience
//
//  Protocol-based convenience operators that use L2 norm.
//

import UncertainValueCore

// MARK: - Additive Operators

public func + <T: UncertainAdditive>(lhs: T, rhs: T) -> T {
    lhs.adding(rhs, using: .l2)
}

public func - <T: UncertainAdditive>(lhs: T, rhs: T) -> T {
    lhs.subtracting(rhs, using: .l2)
}

// MARK: - Multiplicative Operators

public func * <T: UncertainMultiplicative>(lhs: T, rhs: T) -> T {
    lhs.multiplying(rhs, using: .l2)
}

/// Division for non-zero types (never optional).
public func / <T: NonZeroInvertibleUncertainMultiplicative>(lhs: T, rhs: T) -> T {
    lhs.dividingAssumingNonZero(by: rhs, using: .l2)
}

/// Division for types that may contain zero.
public func / <T: InvertibleUncertainMultiplicative>(lhs: T, rhs: T) -> T? {
    lhs.dividingOrNil(by: rhs, using: .l2)
}
