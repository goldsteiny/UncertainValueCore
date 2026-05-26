//
//  Array+SampleStandardDeviation.swift
//  UncertainValueStatistics
//
//  Sample standard deviation for arrays.
//  Uses L2 norm (standard Euclidean) for all calculations.
//

import Foundation
import UncertainValueCore
import UncertainValueSupport

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

        return try deviations.normalizedScalableReduce { UncertainValueSupport.norm2($0) } / Darwin.sqrt(n - 1)
    }
}

extension Array where Element == UncertainValue {
    /// Computes the sample standard deviation with error propagation.
    /// Value: norm2(deviations) / sqrt(n-1)
    /// Error: first-order Gaussian propagation using
    ///        ∂σ/∂xᵢ = (xᵢ - μ) / ((n - 1)σ).
    /// - Returns: Sample standard deviation with uncertainty.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 2 elements.
    public func sampleStandardDeviationL2() throws -> UncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        let n = Double(count)
        let vals = values

        let resultValue = try vals.sampleStandardDeviationL2()
        if resultValue == 0 {
            return UncertainValue(resultValue, absoluteError: 0)
        }

        let mean = try vals.valuesMean()
        let denominator = (n - 1) * resultValue
        if !denominator.isFinite || denominator == 0 {
            return UncertainValue(resultValue, absoluteError: 0)
        }

        let scaledErrors = zip(vals, absoluteErrors).map { value, error in
            ((value - mean) / denominator) * error
        }
        let resultError = UncertainValueSupport.norm2(scaledErrors)

        return UncertainValue(resultValue, absoluteError: resultError)
    }
}
