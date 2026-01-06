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
/// - Returns: Result with propagated error.
/// - Throws: `UncertainValueError.negativeInput` if base < 0,
///           `UncertainValueError.invalidValue` if base is 0 with error or non-positive exponent,
///           `UncertainValueError.nonFinite` if result overflows/underflows.
public func ** (lhs: UncertainValue, rhs: Double) throws -> UncertainValue {
    try lhs.raised(to: rhs)
}
