//
//  NonZero.swift
//  UncertainValueCoreAlgebra
//
//  Type-safe wrapper guaranteeing a non-zero (and finite, for floats) value.
//

public struct NonZero<T: Numeric & Equatable & Sendable>: Sendable {
    public let value: T

    init(unchecked value: T) { self.value = value }
}

// MARK: - Failable constructors

public extension NonZero {
    init?(_ value: T) {
        guard value != .zero else { return nil }
        self.init(unchecked: value)
    }
}

public extension NonZero where T: BinaryFloatingPoint {
    init?(_ value: T) {
        guard value != .zero, value.isFinite else { return nil }
        self.init(unchecked: value)
    }
}

// MARK: - Well-known constants

public extension NonZero where T: BinaryFloatingPoint {
    static var one: NonZero { NonZero(unchecked: 1) }
    static var negativeOne: NonZero { NonZero(unchecked: -1) }
}

// MARK: - Equatable, Hashable

extension NonZero: Equatable {}
extension NonZero: Hashable where T: Hashable {}

// MARK: - Arithmetic with T

public func * <T: Numeric & Equatable & Sendable>(lhs: T, rhs: NonZero<T>) -> T {
    lhs * rhs.value
}

public func * <T: Numeric & Equatable & Sendable>(lhs: NonZero<T>, rhs: T) -> T {
    lhs.value * rhs
}

public func / <T: BinaryFloatingPoint & Sendable>(lhs: T, rhs: NonZero<T>) -> T {
    lhs / rhs.value
}
