//
//  NonZero.swift
//  UncertainValueCoreAlgebra
//
//  Type-safe wrapper guaranteeing a non-zero value.
//

public struct NonZero<Value: Zero & Sendable>: Sendable {
    public let value: Value

    @inlinable
    public init?(_ value: Value) {
        guard !value.isZero else { return nil }
        self.value = value
    }

    @inlinable
    public init(unchecked value: Value) {
        precondition(!value.isZero, "NonZero(unchecked:) received zero.")
        self.value = value
    }
}

public extension NonZero where Value: One {
    @inlinable
    static var one: NonZero {
        NonZero(unchecked: .one)
    }
}

public extension NonZero where Value: MultiplicativeMonoidWithUnits {
    @inlinable
    var unit: Unit<Value>? {
        value.unit
    }
}

extension NonZero: Equatable where Value: Equatable {}
extension NonZero: Hashable where Value: Hashable {}

public func * <Value: MultiplicativeSemigroup>(lhs: Value, rhs: NonZero<Value>) -> Value {
    lhs * rhs.value
}

public func * <Value: MultiplicativeSemigroup>(lhs: NonZero<Value>, rhs: Value) -> Value {
    lhs.value * rhs
}
