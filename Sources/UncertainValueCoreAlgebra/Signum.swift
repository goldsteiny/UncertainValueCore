//
//  Signum.swift
//  UncertainValueCoreAlgebra
//
//  Sign helpers for value types.
//

import Foundation

/// A three-valued sign representation.
public enum Signum: Int, Sendable, Codable, CaseIterable {
    case negative = -1
    case zero = 0
    case positive = 1
}

/// Base protocol for types that can report sign (negative/zero/positive).
public protocol SignumProvidingBase: Sendable {
    var signum: Signum { get }
}

/// Signum provider for types that can represent zero.
public protocol SignumProviding: SignumProvidingBase, ZeroContaining {}

/// Protocol for types that can provide a sign-free (absolute) value.
public protocol SignMagnitudeProviding: SignumProvidingBase {
    /// Absolute value of the receiver (sign removed).
    var absolute: Self { get }
}

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
