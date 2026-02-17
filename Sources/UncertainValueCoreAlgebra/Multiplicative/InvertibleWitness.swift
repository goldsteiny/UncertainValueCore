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

/// Canonical witness type for units in structures with partial reciprocal.
public struct Unit<Element: MultiplicativeMonoidWithPartialReciprocal>: MultiplicativeInvertible, Sendable {
    public let value: Element
    public let reciprocal: Element

    /// Returns nil when the element does not admit a reciprocal.
    @inlinable
    public init?(_ value: Element) {
        guard case .success(let reciprocal) = value.reciprocal() else { return nil }
        self.value = value
        self.reciprocal = reciprocal
    }

    @inlinable
    public init(unchecked value: Element, reciprocal: Element) {
        self.value = value
        self.reciprocal = reciprocal
    }
}

extension Unit: Equatable where Element: Equatable {}
extension Unit: Hashable where Element: Hashable {}

public func / <Element: MultiplicativeSemigroup, Inverse: MultiplicativeInvertible>(lhs: Element, rhs: Inverse) -> Element where Inverse.Element == Element {
    lhs * rhs.reciprocal
}
