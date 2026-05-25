//
//  Array+GiniCoefficient.swift
//  UncertainValueStatistics
//
//  Gini coefficient for non-negative samples, with Gaussian propagation for uncertain samples.
//

import Foundation
import UncertainValueCore
import UncertainValueSupport

extension Array where Element == Double {
    /// Computes the (uncorrected) sample Gini coefficient for non-negative values.
    ///
    /// Domain constraints:
    /// - At least 2 values
    /// - All values finite
    /// - All values non-negative
    /// - Sum(values) > 0
    ///
    /// Formula:
    /// G = sum_i((2i - n - 1) * x_(i)) / (n * sum_i(x_i)), where x_(i) are sorted ascending.
    ///
    /// - Returns: Gini coefficient in [0, (n-1)/n] for valid finite samples.
    /// - Throws: `UncertainValueError` for invalid input domain.
    public func giniCoefficientL2() throws -> Double {
        try GiniEvaluation.valueOnly(values: self)
    }
}

extension Array where Element == UncertainValue {
    /// Computes the (uncorrected) sample Gini coefficient with Gaussian error propagation.
    ///
    /// Domain constraints match `[Double].giniCoefficientL2()` and additionally require
    /// finite per-sample absolute uncertainties.
    ///
    /// Propagation uses local first-order sensitivities:
    /// delta(G)^2 = sum_i((dG/dx_i)^2 * delta(x_i)^2)
    ///
    /// Tie handling:
    /// For ties, sensitivities use the symmetric pairwise derivative (sign(0)=0),
    /// avoiding order-dependent artifacts from arbitrary tie ordering.
    ///
    /// - Returns: Gini coefficient as `UncertainValue`.
    /// - Throws: `UncertainValueError` for invalid input domain.
    public func giniCoefficientL2() throws -> UncertainValue {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }
        guard allSatisfy({ $0.absoluteError.isFinite }) else {
            throw UncertainValueError.nonFinite
        }

        let evaluation = try GiniEvaluation.valueAndPartials(values: values)
        let propagatedErrorSquared = zip(evaluation.partials, absoluteErrors).reduce(0.0) { sum, pair in
            let (partial, sigma) = pair
            let term = partial * sigma
            return sum + (term * term)
        }
        let propagatedError = sqrt(propagatedErrorSquared)

        guard propagatedError.isFinite else {
            throw UncertainValueError.nonFinite
        }
        return UncertainValue(evaluation.value, absoluteError: propagatedError)
    }
}

private enum GiniEvaluation {
    static func valueOnly(values: [Double]) throws -> Double {
        let (n, sum) = try validateDomain(values: values)
        let sorted = values.sorted()
        let numerator = sorted.enumerated().reduce(0.0) { acc, element in
            let (index, x) = element
            let i = Double(index + 1)
            return acc + ((2 * i - n - 1) * x)
        }
        let gini = numerator / (n * sum)

        guard gini.isFinite else {
            throw UncertainValueError.nonFinite
        }
        return gini
    }

    static func valueAndPartials(values: [Double]) throws -> (value: Double, partials: [Double]) {
        let (n, sum) = try validateDomain(values: values)

        // Partials via symmetric pairwise derivative to avoid tie-order artifacts.
        var pairwiseAbsSum = 0.0
        var signedComparisons = Array(repeating: 0.0, count: values.count)

        for i in 0..<values.count {
            for j in (i + 1)..<values.count {
                let difference = values[i] - values[j]
                pairwiseAbsSum += abs(difference)
                if difference > 0 {
                    signedComparisons[i] += 1
                    signedComparisons[j] -= 1
                } else if difference < 0 {
                    signedComparisons[i] -= 1
                    signedComparisons[j] += 1
                }
            }
        }

        let pairwiseGini = pairwiseAbsSum / (n * sum)
        let partials = signedComparisons.map { signedRank in
            (signedRank / (n * sum)) - (pairwiseGini / sum)
        }

        guard pairwiseGini.isFinite,
              partials.allSatisfy(\.isFinite) else {
            throw UncertainValueError.nonFinite
        }

        return (pairwiseGini, partials)
    }

    private static func validateDomain(values: [Double]) throws -> (n: Double, sum: Double) {
        guard values.count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: values.count)
        }
        guard values.allSatisfy(\.isFinite) else {
            throw UncertainValueError.nonFinite
        }
        guard values.allSatisfy({ $0 >= 0 }) else {
            throw UncertainValueError.negativeInput
        }

        let n = Double(values.count)
        let sum = values.sum
        guard sum.isFinite else {
            throw UncertainValueError.nonFinite
        }
        guard sum > 0 else {
            throw UncertainValueError.divisionByZero
        }
        return (n, sum)
    }
}
