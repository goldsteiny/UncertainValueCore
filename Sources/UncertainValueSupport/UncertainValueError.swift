//
//  UncertainValueError.swift
//  UncertainValueSupport
//
//  Error types for invalid uncertainty operations.
//

public enum UncertainValueError: Error, Equatable, Hashable, Sendable {
    case divisionByZero
    case emptyCollection
    case insufficientElements(required: Int, actual: Int)
    case nonPositiveInput
    case negativeInput
    case zeroInput
    case invalidScale
    case nonFinite
    case invalidValue
    case invalidMultiplicativeError
    case mixedSigns
    case overflow
    case underflow
}
