//
//  Raisable.swift
//  UncertainValueCoreAlgebra
//
//  Exponentiation protocols using Result.
//

public protocol DiscreteRaisable: Sendable {
    func raised(to power: Int) -> Result<Self, AlgebraError.NonFiniteResult>
}

public protocol SignedRaisable: DiscreteRaisable, Signed {
    associatedtype Scalar: BinaryFloatingPoint
    func raised(to power: Scalar) -> Result<Self, AlgebraError>
}

public extension SignedRaisable where Self: AbsoluteValueDecomposable, Scalar == Double {
    @inlinable
    func raised(to power: Int) -> Result<Self, AlgebraError> {
        absolute.raised(to: Double(power)).map { result in
            switch signum {
            case .negative where !power.isMultiple(of: 2):
                return -result
            default:
                return result
            }
        }
    }
}
