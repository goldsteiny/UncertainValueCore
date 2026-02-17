//
//  AlgebraErrors.swift
//  UncertainValueCoreAlgebra
//
//  Typed failures for partial algebraic operations.
//

public struct ReciprocalOfZeroError: Error, Equatable, Sendable {
    public let context: String?

    public init(_ context: String? = nil) {
        self.context = context
    }
}

public struct DivisionByZeroError: Error, Equatable, Sendable {
    public let context: String?

    public init(_ context: String? = nil) {
        self.context = context
    }
}

public struct EmptyCollectionError: Error, Equatable, Sendable {
    public let context: String?

    public init(_ context: String? = nil) {
        self.context = context
    }
}

/// Optional umbrella when callers prefer a single algebra error domain.
public enum AlgebraError: Error, Equatable, Sendable {
    case reciprocalOfZero(ReciprocalOfZeroError)
    case divisionByZero(DivisionByZeroError)
    case emptyCollection(EmptyCollectionError)
}

public protocol AlgebraErrorConvertible: Error {
    var asAlgebraError: AlgebraError { get }
}

extension ReciprocalOfZeroError: AlgebraErrorConvertible {
    public var asAlgebraError: AlgebraError { .reciprocalOfZero(self) }
}

extension DivisionByZeroError: AlgebraErrorConvertible {
    public var asAlgebraError: AlgebraError { .divisionByZero(self) }
}

extension EmptyCollectionError: AlgebraErrorConvertible {
    public var asAlgebraError: AlgebraError { .emptyCollection(self) }
}

public extension Result where Failure: AlgebraErrorConvertible {
    @inlinable
    func mapToAlgebraError() -> Result<Success, AlgebraError> {
        mapError(\.asAlgebraError)
    }
}
