import Foundation
import UncertainValueCore
import UncertainValueSupport

extension Array where Element == Double {
    /// Computes z-scores using sample standard deviation.
    /// Formula: z_i = (x_i − μ) / σ
    /// - Returns: Array of z-scores (same length as input).
    /// - Throws: `UncertainValueError.insufficientElements` if fewer than 2 elements,
    ///           `UncertainValueError.divisionByZero` if all values are equal (σ = 0).
    public func zTransformL2() throws -> [Double] {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        let mean = try valuesMean()
        let sigma = try sampleStandardDeviationL2()
        guard sigma > 0 else { throw UncertainValueError.divisionByZero }

        return map { ($0 - mean) / sigma }
    }
}

extension Array where Element == UncertainValue {
    /// Computes z-scores with full correlated Gaussian error propagation.
    ///
    /// Each z_i depends on all x_j through μ and σ, so the error propagation
    /// uses the sensitivity matrix A_ij = δ_ij − 1/N − z_i·z_j/(N−1):
    ///
    ///     Δz_i = (1/σ) √(Σ_j A_ij² · Δx_j²)
    ///
    /// - Returns: Array of z-scores with propagated uncertainties.
    /// - Throws: `UncertainValueError.insufficientElements` if fewer than 2 elements,
    ///           `UncertainValueError.divisionByZero` if all values are equal (σ = 0).
    public func zTransformL2() throws -> [UncertainValue] {
        guard count >= 2 else {
            throw UncertainValueError.insufficientElements(required: 2, actual: count)
        }

        let vals = values
        let errs = absoluteErrors

        let zScores = try vals.zTransformL2()
        let sigma = try vals.sampleStandardDeviationL2()

        let n = Double(count)
        let invN = 1.0 / n
        let invNm1 = 1.0 / (n - 1.0)
        let invSigma = 1.0 / sigma

        let zErrors = zScores.enumerated().map { i, zi -> Double in
            let sumSq = zip(zScores, errs).enumerated().reduce(0.0) { sum, element in
                let (j, (zj, errJ)) = element
                let aij = (i == j ? 1.0 : 0.0) - invN - zi * zj * invNm1
                let term = aij * errJ
                return sum + term * term
            }
            return Darwin.sqrt(sumSq) * invSigma
        }

        return zip(zScores, zErrors).map { UncertainValue($0, absoluteError: $1) }
    }
}
