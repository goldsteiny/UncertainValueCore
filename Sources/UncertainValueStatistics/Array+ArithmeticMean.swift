//
//  Array+ArithmeticMean.swift
//  UncertainValueStatistics
//
//  Arithmetic mean with standard deviation as uncertainty.
//  Uses L2 norm (standard Euclidean) for all calculations.
//

import Accelerate
import Foundation
import UncertainValueCore
import UncertainValueCoreAlgebra

extension Array where Element == Double {

    /// Applies a reduction function with max-value normalization for numerical stability.
    /// - Parameter f: Reduction function to apply to normalized values.
    /// - Returns: Scaled result.
    /// - Throws: `UncertainValueError.emptyCollection` if array is empty.
    func normalizedScalableReduce(_ f: ([Double]) -> Double) throws -> Double {
        guard !isEmpty else {
            throw UncertainValueError.emptyCollection
        }

        let maxAbsValue = map { abs($0) }.max() ?? 0
        guard maxAbsValue > 0 else {
            return 0.0
        }

        let normalized = map { $0 / maxAbsValue }
        return maxAbsValue * f(normalized)
    }

    /// Mean of values using normalized reduce for numerical stability.
    /// - Throws: `UncertainValueError.emptyCollection` if array is empty.
    func valuesMean() throws -> Double {
        try normalizedScalableReduce { $0.reduce(0, +) / Double(count) }
    }

    /// Computes the arithmetic mean with sample standard deviation as uncertainty.
    /// Uses normalization by max value for numerical stability with extreme values.
    /// - Returns: UncertainValue where value is the mean and absoluteError is the sample standard deviation.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    public func arithmeticMeanL2() throws -> UncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        return UncertainValue(try valuesMean(), absoluteError: try sampleStandardDeviationL2())
    }

    /// Computes the arithmetic mean with sample standard deviation as uncertainty.
    /// Uses Apple's Accelerate framework (vDSP) for optimized computation.
    /// Recommended for arrays with >1000 elements.
    /// - Returns: UncertainValue where value is the mean and absoluteError is the sample standard deviation.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    public func arithmeticMeanL2_vDSP() throws -> UncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        let mean = vDSP.mean(self)

        // Compute std dev using vDSP primitives: subtract mean, then rootMeanSquare
        let meanVector = [Double](repeating: mean, count: count)
        let deviations = vDSP.subtract(self, meanVector)
        let rms = vDSP.rootMeanSquare(deviations)

        // rms = sqrt(sum(d^2)/n), convert to sample std dev: multiply by sqrt(n/(n-1))
        let n = Double(count)
        let sampleStdDev = rms * Darwin.sqrt(n / (n - 1))

        return UncertainValue(mean, absoluteError: sampleStdDev)
    }
}

extension Array where Element == UncertainValue {
    /// Computes the arithmetic mean with error propagation using L2 norm.
    /// - Returns: Mean value with combined and scaled uncertainty.
    /// - Throws: `UncertainValueError.emptyCollection` if array is empty.
    public func arithmeticMeanL2() throws -> UncertainValue {
        try mean(using: .l2)
    }
}
