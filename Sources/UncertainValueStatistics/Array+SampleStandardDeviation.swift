//
//  Array+SampleStandardDeviation.swift
//  UncertainValueStatistics
//
//  Sample standard deviation for arrays.
//  Uses L2 norm (standard Euclidean) for all calculations.
//

import Foundation
import UncertainValueCore

extension Array where Element == Double {
    /// Computes the sample standard deviation.
    /// Formula: sqrt(sum((x - mean)^2) / (n-1)) = norm2(deviations) / sqrt(n-1)
    /// - Returns: Sample standard deviation.
    /// - Precondition: Array must contain at least 2 elements.
    public func sampleStandardDeviationL2() -> Double {
        precondition(count >= 2, "Sample standard deviation requires at least 2 values")

        let n = Double(count)
        let mean = valuesMean
        let deviations = map { $0 - mean }

        return deviations.normalizedScalableReduce { UncertainValueCore.norm2($0) } / Darwin.sqrt(n - 1)
    }
}

extension Array where Element == UncertainValue {
    /// Computes the sample standard deviation with error propagation.
    /// Value: norm2(deviations) / sqrt(n-1)
    /// Error: propagated from individual measurement errors using L2 norm.
    /// - Returns: Sample standard deviation with uncertainty.
    /// - Precondition: Array must contain at least 2 elements.
    public func sampleStandardDeviationL2() -> UncertainValue {
        precondition(count >= 2, "Sample standard deviation requires at least 2 values")

        let n = Double(count)
        let vals = values

        let resultValue = vals.sampleStandardDeviationL2()

        let mean = vals.valuesMean
        let scaledDeviations = vals.map { ($0 - mean) / Darwin.sqrt(n - 1) }
        let scaledErrors: [Double] = zip(scaledDeviations, absoluteErrors).map(*)
        let resultError = UncertainValueCore.norm2(scaledErrors)

        return UncertainValue(resultValue, absoluteError: resultError)
    }
}
