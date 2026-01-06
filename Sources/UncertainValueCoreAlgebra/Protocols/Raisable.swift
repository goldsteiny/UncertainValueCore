//
//  Raisable.swift
//  UncertainValueCoreAlgebra
//
//  Exponentiation protocols.
//

import Foundation

/// Exponentiation by integer powers.
public protocol DiscreteRaisable: Sendable {
    /// Raises to an integer power.
    /// - Parameter power: Integer exponent.
    /// - Returns: Result of exponentiation.
    /// - Throws: `UncertainValueError.nonFinite` if result overflows/underflows.
    func raised(to power: Int) throws -> Self
}

/// Exponentiation by real powers for signed values.
public protocol SignedRaisable: DiscreteRaisable, SignumProvidingBase {
    associatedtype Scalar: BinaryFloatingPoint
    /// Raises to a real power.
    /// - Parameter power: Real exponent.
    /// - Returns: Result of exponentiation.
    /// - Throws: `UncertainValueError.negativeInput` if base is negative,
    ///           `UncertainValueError.nonFinite` if result overflows/underflows.
    func raised(to power: Scalar) throws -> Self
}

public extension SignedRaisable where Self: SignMagnitudeProviding, Scalar == Double {
    /// Default integer-power behavior for signed values uses the magnitude.
    @inlinable
    func raised(to power: Int) throws -> Self {
        let resultAbsolute = try absolute.raised(to: Double(power))

        switch signum {
        case .negative:
            return power.isMultiple(of: 2) ? resultAbsolute : resultAbsolute.flippedSign
        default:
            return resultAbsolute
        }
    }
}
