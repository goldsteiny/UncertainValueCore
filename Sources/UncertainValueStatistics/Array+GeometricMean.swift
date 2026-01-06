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
    /// Internal implementation for geometric mean computation.
    /// - Parameter arithmeticMean: Function to compute arithmetic mean of log values.
    private func geometricMeanL2(using arithmeticMean: ([Double]) throws -> UncertainValue) throws -> MultiplicativeUncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }
        guard allSatisfy({ $0 != 0 }) else {
            throw UncertainValueError.zeroInput
        }

        let allPositive = allSatisfy { $0 > 0 }
        let allNegative = allSatisfy { $0 < 0 }
        guard allPositive || allNegative else {
            throw UncertainValueError.mixedSigns
        }

        let logAbsValues = map { Darwin.log(abs($0)) }
        let logMean = try arithmeticMean(logAbsValues)
        let resultSignum: Signum = allPositive ? .positive : .negative

        return try MultiplicativeUncertainValue(logAbs: logMean, signum: resultSignum)
    }

    /// Computes the geometric mean with log-space sample standard deviation as uncertainty.
    ///
    /// All values must share the same sign (all positive or all negative).
    /// The result inherits the common sign.
    ///
    /// - Returns: MultiplicativeUncertainValue where logAbs is the arithmetic mean of log(|values|).
    /// - Throws:
    ///   - `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    ///   - `UncertainValueError.invalidValue` if any value is zero.
    ///   - `UncertainValueError.mixedSigns` if values have inconsistent signs.
    public func geometricMeanL2() throws -> MultiplicativeUncertainValue {
        try geometricMeanL2(using: { try $0.arithmeticMeanL2() })
    }

    /// Computes the geometric mean with log-space sample standard deviation as uncertainty.
    /// Uses Apple's Accelerate framework (vDSP) for optimized computation.
    /// Recommended for arrays with >1000 elements.
    ///
    /// All values must share the same sign (all positive or all negative).
    /// The result inherits the common sign.
    ///
    /// - Returns: MultiplicativeUncertainValue where logAbs is the arithmetic mean of log(|values|).
    /// - Throws:
    ///   - `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    ///   - `UncertainValueError.invalidValue` if any value is zero.
    ///   - `UncertainValueError.mixedSigns` if values have inconsistent signs.
    public func geometricMeanL2_vDSP() throws -> MultiplicativeUncertainValue {
        try geometricMeanL2(using: { try $0.arithmeticMeanL2_vDSP() })
    }
}
