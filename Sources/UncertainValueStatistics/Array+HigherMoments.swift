//
//  Array+HigherMoments.swift
//  UncertainValueStatistics
//
//  Sample skewness and excess kurtosis for arrays.
//  Uses L2 norm (standard Euclidean) for all calculations.
//

import Foundation
import UncertainValueSupport

extension Array where Element == Double {
    /// Computes the sample skewness (third standardized moment).
    /// Positive values indicate right-skewed distributions; negative indicate left-skewed.
    /// Uses the adjusted Fisher-Pearson coefficient: n/((n-1)(n-2)) * sum((x-mean)/s)^3.
    /// - Returns: Sample skewness.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 3 elements.
    public func skewnessL2() throws -> Double {
        guard count >= 3 else {
            throw UncertainValueError.insufficientElements(required: 3, actual: count)
        }

        let n = Double(count)
        let mean = try valuesMean()
        let sigma = try sampleStandardDeviationL2()

        guard sigma > 0 else { return 0.0 }

        let cubedDeviations = map { pow(($0 - mean) / sigma, 3.0) }
        let adjustment = n / ((n - 1) * (n - 2))
        return adjustment * cubedDeviations.reduce(0, +)
    }

    /// Computes the sample excess kurtosis (fourth standardized moment minus 3).
    /// Zero for a normal distribution; positive for heavy-tailed, negative for light-tailed.
    /// Uses the bias-corrected estimator.
    /// - Returns: Sample excess kurtosis.
    /// - Throws: `UncertainValueError.insufficientElements` if array has fewer than 4 elements.
    public func excessKurtosisL2() throws -> Double {
        guard count >= 4 else {
            throw UncertainValueError.insufficientElements(required: 4, actual: count)
        }

        let n = Double(count)
        let mean = try valuesMean()
        let sigma = try sampleStandardDeviationL2()

        guard sigma > 0 else { return 0.0 }

        let fourthDeviations = map { pow(($0 - mean) / sigma, 4.0) }
        let rawKurtosis = fourthDeviations.reduce(0, +) / n

        let a = (n - 1) / ((n - 2) * (n - 3))
        return a * ((n + 1) * rawKurtosis - 3 * (n - 1))
    }
}
