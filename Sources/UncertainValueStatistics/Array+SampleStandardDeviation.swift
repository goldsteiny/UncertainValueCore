//
//  Array+SampleStandardDeviation.swift
//  UncertainValueStatistics
//
//  Sample standard deviation for arrays.
//  Uses L2 norm (standard Euclidean) for all calculations.
//

import Foundation
import UncertainValueCore
import UncertainValueCoreAlgebra

extension Array where Element == Double {
    /// Computes the sample standard deviation.
    /// Formula: sqrt(sum((x - mean)^2) / (n-1)) = norm2(deviations) / sqrt(n-1)
    /// - Returns: Sample standard deviation.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    public func sampleStandardDeviationL2() throws -> Double {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        let n = Double(count)
        let mean = try valuesMean()
        let deviations = map { $0 - mean }

        return try deviations.normalizedScalableReduce { UncertainValueCoreAlgebra.norm2($0) } / Darwin.sqrt(n - 1)
    }
}

extension Array where Element == UncertainValue {
    /// Computes the sample standard deviation with error propagation.
    /// Value: norm2(deviations) / sqrt(n-1)
    /// Error: propagated from individual measurement errors using L2 norm.
    /// - Returns: Sample standard deviation with uncertainty.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    public func sampleStandardDeviationL2() throws -> UncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        let n = Double(count)
        let vals = values

        let resultValue = try vals.sampleStandardDeviationL2()

        let mean = try vals.valuesMean()
        let scaledDeviations = vals.map { ($0 - mean) / Darwin.sqrt(n - 1) }
        let scaledErrors: [Double] = zip(scaledDeviations, absoluteErrors).map(*)
        let resultError = UncertainValueCoreAlgebra.norm2(scaledErrors)

        return UncertainValue(resultValue, absoluteError: resultError)
    }
}
