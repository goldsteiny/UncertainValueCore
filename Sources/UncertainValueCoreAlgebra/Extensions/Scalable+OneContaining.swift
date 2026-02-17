//
//  Scalable+OneContaining.swift
//  UncertainValueCoreAlgebra
//
//  Convenience for creating scaled identities.
//

public extension Scalable where Self: OneContaining {
    static func scaledOne(_ value: NonZero<Scalar>) -> Self {
        one.scaled(by: value)
    }
}
