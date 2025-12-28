//
//  UncertainValue+Exponentiation.swift
//  UncertainValueCore
//
//  Ergonomic exponent operator ** for UncertainValue.
//

import Foundation

// MARK: - Exponentiation Operator

precedencegroup ExponentiationPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: right
}

infix operator ** : ExponentiationPrecedence

/// Raises an UncertainValue to a power.
/// - Parameters:
///   - lhs: The base value with uncertainty.
///   - rhs: The exponent.
/// - Returns: Result with propagated error, or nil if base <= 0.
public func ** (lhs: UncertainValue, rhs: Double) -> UncertainValue? {
    lhs.raised(to: rhs)
}
