//
//  Signum.swift
//  UncertainValueCore
//
//  Sign helpers for value types that can express negative/zero/positive.
//

import Foundation

/// A three-valued sign representation.
public enum Signum: Int, Sendable, Codable, CaseIterable {
    case negative = -1
    case zero = 0
    case positive = 1
}

/// Protocol for types that can report sign (negative/zero/positive).
public protocol SignumProviding: Sendable {
    var signum: Signum { get }
}

public extension SignumProviding {
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

/// Protocol for types that can provide a sign-free (absolute) value.
public protocol SignMagnitudeProviding: SignumProviding {
    /// Absolute value of the receiver (sign removed).
    var absolute: Self { get }
}
