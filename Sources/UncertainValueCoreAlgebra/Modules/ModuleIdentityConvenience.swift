//
//  ModuleIdentityConvenience.swift
//  UncertainValueCoreAlgebra
//
//  Convenience for scaling multiplicative identity.
//

public extension LeftModule where Self: One {
    @inlinable
    static func scaledOne(by scalar: Scalar) -> Self {
        one.leftScaled(by: scalar)
    }
}

public extension RightModule where Self: One {
    @inlinable
    static func rightScaledOne(by scalar: Scalar) -> Self {
        one.rightScaled(by: scalar)
    }
}
