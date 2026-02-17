//
//  InvertibleWitness.swift
//  UncertainValueCoreAlgebra
//
//  Witnesses for multiplicative invertibility (units).
//

/// A witness that a concrete element is multiplicatively invertible.
public protocol MultiplicativeInvertible: Sendable {
    associatedtype Element: MultiplicativeSemigroup
    var value: Element { get }
    var reciprocal: Element { get }
}

/// Backward-compatible spelling alias.
public typealias MultiplicativeInvertiable = MultiplicativeInvertible

/// Canonical witness type for units (invertible elements).
public struct Unit<Element: MultiplicativeSemigroup>: MultiplicativeInvertible, Sendable {
    public let value: Element
    public let reciprocal: Element

    @inlinable
    public init(unchecked value: Element, reciprocal: Element) {
        self.value = value
        self.reciprocal = reciprocal
    }
}

public extension Unit where Element: MultiplicativeMonoidWithUnits {
    /// Returns nil when the element is not a unit.
    @inlinable
    init?(_ value: Element) {
        guard let unit = value.unit else { return nil }
        self = unit
    }
}

extension Unit: Equatable where Element: Equatable {}
extension Unit: Hashable where Element: Hashable {}

public func / <Element: MultiplicativeSemigroup, Inverse: MultiplicativeInvertible>(lhs: Element, rhs: Inverse) -> Element where Inverse.Element == Element {
    lhs * rhs.reciprocal
}
