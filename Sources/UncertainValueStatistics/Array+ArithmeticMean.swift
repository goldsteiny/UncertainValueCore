//
//  Array+ArithmeticMean.swift
//  UncertainValueStatistics
//
//  Arithmetic mean with standard deviation as uncertainty.
//

import Accelerate
import Foundation
import UncertainValueCore

extension Array where Element == Double {
    /// Computes the arithmetic mean with sample standard deviation as uncertainty.
    /// Uses normalization by max value for numerical stability with extreme values.
    /// - Returns: UncertainValue where value is the mean and absoluteError is the sample standard deviation.
    /// - Precondition: Array must contain at least 2 elements.
    public func arithmeticMean() -> UncertainValue {
        precondition(count >= 2, "Arithmetic mean requires at least 2 values for standard deviation")

        // Normalize by max absolute value for numerical stability
        let maxValue = map { abs($0) }.max() ?? 0
        guard maxValue > 0 else {
            return UncertainValue(0, absoluteError: 0)
        }

        let normalized = map { $0 / maxValue }
        let n = Double(count)
        let normalizedMean = normalized.reduce(0, +) / n

        let normalizedDeviations = normalized.map { $0 - normalizedMean }
        let normalizedStdDev = UncertainValueCore.norm2(normalizedDeviations) / Darwin.sqrt(n - 1)

        return UncertainValue(maxValue * normalizedMean, absoluteError: maxValue * normalizedStdDev)
    }

    /// Computes the arithmetic mean with sample standard deviation as uncertainty.
    /// Uses Apple's Accelerate framework (vDSP) for optimized computation.
    /// - Returns: UncertainValue where value is the mean and absoluteError is the sample standard deviation.
    /// - Precondition: Array must contain at least 2 elements.
    public func arithmeticMean_vDSP() -> UncertainValue {
        precondition(count >= 2, "Arithmetic mean requires at least 2 values for standard deviation")

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
