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

public extension SignedRaisable where Self: SignMagnitudeProviding, Scalar == Double {
    /// Default integer-power behavior for signed values uses the magnitude.
    @inlinable
    func raised(to power: Int) -> Self? {
        guard let resultAbsolute = absolute.raised(to: Double(power)) else {
            return nil
        }
        
        switch signum {
        case .negative:
            return power.isMultiple(of: 2) ? resultAbsolute : resultAbsolute.flippedSign
        default:
            return resultAbsolute
        }
    }
}
