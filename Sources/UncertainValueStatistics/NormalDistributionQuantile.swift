//
//  NormalDistributionQuantile.swift
//  UncertainValueStatistics
//
//  Inverse cumulative distribution function (quantile function)
//  for the standard normal distribution.
//

import Foundation

public enum NormalDistribution {
    /// Computes the inverse CDF (quantile function) of the standard normal distribution.
    /// Uses the rational approximation from Abramowitz & Stegun (formula 26.2.23)
    /// with refinement by P.J. Acklam for full-range accuracy.
    /// - Parameter p: Probability in the open interval (0, 1).
    /// - Returns: The z-score such that P(Z <= z) = p for Z ~ N(0,1).
    public static func inverseCDF(_ p: Double) -> Double {
        guard p > 0, p < 1 else {
            if p <= 0 { return -.infinity }
            return .infinity
        }

        if p < pLow {
            return lowRegionApproximation(p)
        } else if p <= pHigh {
            return centralRegionApproximation(p)
        } else {
            return -lowRegionApproximation(1 - p)
        }
    }
}

private extension NormalDistribution {
    static let pLow = 0.02425
    static let pHigh = 1 - pLow

    static let a: [Double] = [
        -3.969683028665376e+01,
         2.209460984245205e+02,
        -2.759285104469687e+02,
         1.383577518672690e+02,
        -3.066479806614716e+01,
         2.506628277459239e+00
    ]

    static let b: [Double] = [
        -5.447609879822406e+01,
         1.615858368580409e+02,
        -1.556989798598866e+02,
         6.680131188771972e+01,
        -1.328068155288572e+01
    ]

    static let c: [Double] = [
        -7.784894002430293e-03,
        -3.223964580411365e-01,
        -2.400758277161838e+00,
        -2.549732539343734e+00,
         4.374664141464968e+00,
         2.938163982698783e+00
    ]

    static let d: [Double] = [
         7.784695709041462e-03,
         3.224671290700398e-01,
         2.445134137142996e+00,
         3.754408661907416e+00
    ]

    static func centralRegionApproximation(_ p: Double) -> Double {
        let q = p - 0.5
        let r = q * q

        let numerator = ((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]
        let denominator = ((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1
        return q * numerator / denominator
    }

    static func lowRegionApproximation(_ p: Double) -> Double {
        let q = Darwin.sqrt(-2 * Darwin.log(p))

        let numerator = ((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]
        let denominator = (((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1
        return numerator / denominator
    }
}
