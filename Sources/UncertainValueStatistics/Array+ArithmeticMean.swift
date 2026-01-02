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

extension Array where Element == Double {

    public func normalizedScalableReduce(_ f: ([Double]) -> Double) -> Double {
        precondition(count >= 1, "Scaling requires at least 1 value")

        let maxAbsValue = map { abs($0) }.max() ?? 0
        guard maxAbsValue > 0 else {
            return 0.0
        }

        let normalized = map { $0 / maxAbsValue }
        return maxAbsValue * f(normalized)
    }

    public var valuesMean: Double {
        precondition(count >= 1, "Arithmetic mean requires at least 1 value")

        return normalizedScalableReduce { $0.reduce(0, +) / Double(count) }
    }

    /// Computes the arithmetic mean with sample standard deviation as uncertainty.
    /// Uses normalization by max value for numerical stability with extreme values.
    /// - Returns: UncertainValue where value is the mean and absoluteError is the sample standard deviation.
    /// - Precondition: Array must contain at least 2 elements.
    public func arithmeticMean() -> UncertainValue {
        precondition(count >= 2, "Arithmetic mean requires at least 2 values for standard deviation")

        return UncertainValue(valuesMean, absoluteError: sampleStandardDeviation())
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

extension Array where Element == UncertainValue {
    /// Computes the arithmetic mean with error propagation using L2 norm.
    /// - Returns: Mean value with combined and scaled uncertainty.
    /// - Precondition: Array must not be empty.
    public func arithmeticMean() -> UncertainValue {
        precondition(!isEmpty, "Arithmetic mean requires at least 1 value")
        return sum(using: .l2).dividing(by: Double(count))!
    }
}
