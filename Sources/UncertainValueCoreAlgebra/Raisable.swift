//
//  Raisable.swift
//  UncertainValueCoreAlgebra
//
//  Exponentiation protocols.
//

import Foundation

/// Exponentiation by integer powers.
public protocol DiscreteRaisable: Sendable {
    func raised(to power: Int) -> Self?
}

/// Exponentiation by real powers for signed values.
public protocol SignedRaisable: DiscreteRaisable, SignumProvidingBase {
    associatedtype Scalar: BinaryFloatingPoint
    func raised(to power: Scalar) -> Self?
}
