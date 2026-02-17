//
//  Scalable.swift
//  UncertainValueCoreAlgebra
//
//  Module action: scalar multiplication over a field.
//

public protocol Scalable: Sendable {
    associatedtype Scalar: BinaryFloatingPoint & Sendable
    func scaled(by scalar: NonZero<Scalar>) -> Self
}
