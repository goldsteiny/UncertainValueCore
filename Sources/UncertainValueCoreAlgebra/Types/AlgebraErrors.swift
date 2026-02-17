//
//  AlgebraErrors.swift
//  UncertainValueCoreAlgebra
//
//  Domain-specific error types for algebraic operations.
//

public struct DivisionByZeroError: Error, Equatable, Sendable {
    public init() {}
}

public struct InvalidScaleError: Error, Equatable, Sendable {
    public init() {}
}

public struct EmptyCollectionError: Error, Equatable, Sendable {
    public init() {}
}

public struct NonFiniteResultError: Error, Equatable, Sendable {
    public init() {}
}