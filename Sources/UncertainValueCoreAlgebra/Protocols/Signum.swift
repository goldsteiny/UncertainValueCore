//
//  Signum.swift
//  UncertainValueCoreAlgebra
//
//  Sign helpers for value types.
//

/// A three-valued sign representation.
public enum Signum: Int, Sendable, Codable, CaseIterable {
    case negative = -1
    case zero = 0
    case positive = 1
}

public extension Signum {
    var flipped: Signum {
        Signum(rawValue: -rawValue)!
    }
}

/// Signed type with negation. `flippedSign` is the primitive; `prefix -` is derived.
public protocol Signed: Sendable {
    var signum: Signum { get }
    var flippedSign: Self { get }
}

public extension Signed {
    prefix static func - (operand: Self) -> Self { operand.flippedSign }
}

/// Signed type with absolute value decomposition: x = signum × |x|.
public protocol AbsoluteValueDecomposable: Signed {
    var absolute: Self { get }
}
