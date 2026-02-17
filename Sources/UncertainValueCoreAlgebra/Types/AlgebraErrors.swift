//
//  AlgebraErrors.swift
//  UncertainValueCoreAlgebra
//
//  Domain-specific error types for algebraic operations.
//

// MARK: - Sum type (also serves as namespace for individual errors)

public enum AlgebraError: Error, Equatable, Sendable {
    case divisionByZero(DivisionByZero)
    case invalidScale(InvalidScale)
    case emptyCollection(EmptyCollection)
    case nonFiniteResult(NonFiniteResult)
    case incompatibleParameters(IncompatibleParameters)

    // MARK: Individual typed errors for Result<T, E>

    public struct DivisionByZero: Error, Equatable, Sendable {
        public let context: String?
        public init(_ context: String? = nil) { self.context = context }
        public var asAlgebraError: AlgebraError { .divisionByZero(self) }
    }

    public struct InvalidScale: Error, Equatable, Sendable {
        public let context: String?
        public init(_ context: String? = nil) { self.context = context }
        public var asAlgebraError: AlgebraError { .invalidScale(self) }
    }

    public struct EmptyCollection: Error, Equatable, Sendable {
        public let context: String?
        public init(_ context: String? = nil) { self.context = context }
        public var asAlgebraError: AlgebraError { .emptyCollection(self) }
    }

    public struct NonFiniteResult: Error, Equatable, Sendable {
        public let context: String?
        public init(_ context: String? = nil) { self.context = context }
        public var asAlgebraError: AlgebraError { .nonFiniteResult(self) }
    }

    public struct IncompatibleParameters: Error, Equatable, Sendable {
        public let context: String?
        public init(_ context: String? = nil) { self.context = context }
        public var asAlgebraError: AlgebraError { .incompatibleParameters(self) }
    }
}

// MARK: - Result adapter for flatMap composition

public extension Result where Failure: _AlgebraErrorConvertible {
    func mapToAlgebraError() -> Result<Success, AlgebraError> {
        mapError { $0.asAlgebraError }
    }
}

/// Marker constraining `mapToAlgebraError()` to algebra error types.
public protocol _AlgebraErrorConvertible: Error {
    var asAlgebraError: AlgebraError { get }
}

extension AlgebraError.DivisionByZero: _AlgebraErrorConvertible {}
extension AlgebraError.InvalidScale: _AlgebraErrorConvertible {}
extension AlgebraError.EmptyCollection: _AlgebraErrorConvertible {}
extension AlgebraError.NonFiniteResult: _AlgebraErrorConvertible {}
extension AlgebraError.IncompatibleParameters: _AlgebraErrorConvertible {}
