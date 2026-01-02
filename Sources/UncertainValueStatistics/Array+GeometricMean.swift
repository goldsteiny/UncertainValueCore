//
//  Array+GeometricMean.swift
//  UncertainValueStatistics
//
//  Geometric mean with log-space standard deviation as uncertainty.
//

import Foundation
import UncertainValueCore
import MultiplicativeUncertainValue

extension Array where Element == Double {
    /// Computes the geometric mean with log-space sample standard deviation as uncertainty.
    /// - Returns: MultiplicativeUncertainValue where logAbs is the arithmetic mean of log(values).
    /// - Precondition: Array must contain at least 2 elements, all positive.
    public func geometricMean() -> MultiplicativeUncertainValue {
        precondition(count >= 2, "Geometric mean requires at least 2 values for standard deviation")
        precondition(allSatisfy { $0 > 0 }, "Geometric mean requires all values to be positive")

        let logValues = map { Darwin.log($0) }
        let logMean = logValues.arithmeticMean()

        return MultiplicativeUncertainValue(logAbs: logMean, sign: .plus)
    }

    /// Computes the geometric mean with log-space sample standard deviation as uncertainty.
    /// Uses Apple's Accelerate framework (vDSP) for optimized computation.
    /// - Returns: MultiplicativeUncertainValue where logAbs is the arithmetic mean of log(values).
    /// - Precondition: Array must contain at least 2 elements, all positive.
    public func geometricMean_vDSP() -> MultiplicativeUncertainValue {
        precondition(count >= 2, "Geometric mean requires at least 2 values for standard deviation")
        precondition(allSatisfy { $0 > 0 }, "Geometric mean requires all values to be positive")

        let logValues = map { Darwin.log($0) }
        let logMean = logValues.arithmeticMean_vDSP()

        return MultiplicativeUncertainValue(logAbs: logMean, sign: .plus)
    }
}
