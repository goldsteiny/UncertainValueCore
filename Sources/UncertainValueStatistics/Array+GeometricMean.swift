//
//  Array+GeometricMean.swift
//  UncertainValueStatistics
//
//  Geometric mean with log-space standard deviation as uncertainty.
//  Uses L2 norm (standard Euclidean) for all calculations.
//

import Foundation
import UncertainValueCore
import MultiplicativeUncertainValue
import UncertainValueCoreAlgebra

extension Array where Element == Double {
    /// Computes the geometric mean with log-space sample standard deviation as uncertainty.
    /// - Returns: MultiplicativeUncertainValue where logAbs is the arithmetic mean of log(values).
    /// - Throws:
    ///   - `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    ///   - `UncertainValueError.negativeInput` if any value is non-positive.
    public func geometricMeanL2() throws -> MultiplicativeUncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }
        guard allSatisfy({ $0 > 0 }) else {
            throw UncertainValueError.negativeInput
        }

        let logValues = map { Darwin.log($0) }
        let logMean = try logValues.arithmeticMeanL2()

        return try MultiplicativeUncertainValue(logAbs: logMean, sign: .plus)
    }

    /// Computes the geometric mean with log-space sample standard deviation as uncertainty.
    /// Uses Apple's Accelerate framework (vDSP) for optimized computation.
    /// Recommended for arrays with >1000 elements.
    /// - Returns: MultiplicativeUncertainValue where logAbs is the arithmetic mean of log(values).
    /// - Throws:
    ///   - `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    ///   - `UncertainValueError.negativeInput` if any value is non-positive.
    public func geometricMeanL2_vDSP() throws -> MultiplicativeUncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }
        guard allSatisfy({ $0 > 0 }) else {
            throw UncertainValueError.negativeInput
        }

        let logValues = map { Darwin.log($0) }
        let logMean = try logValues.arithmeticMeanL2_vDSP()

        return try MultiplicativeUncertainValue(logAbs: logMean, sign: .plus)
    }
}
