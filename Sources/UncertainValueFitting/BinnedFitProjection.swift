import Foundation
import UncertainValueBinning

/// Typed warnings produced when projecting a `BinnedCountSeries` to a `FitObservationSeries`.
///
/// Lives in `UncertainValueFitting` because all Phase 1 cases are projection/fitting warnings.
/// Phase 2 domain-level warnings (ROI, rebinning) will be operation-specific types.
public enum BinnedFitProjectionWarning: Hashable, Sendable {
    /// One or more zero-count bins were kept in the projection (`.keepWithFallbackWarning`
    /// policy). The associated value is the count of such bins. When δy = 0, the
    /// fitter applies a fallback weight of 1/(1²) = 1 — an implicit, arbitrary influence.
    case zeroCountBinsUseFallbackWeight(count: Int)

    /// One or more included bins have counts below the Gaussian-validity threshold (20).
    /// The Gaussian approximation for count uncertainty is strongly skewed for low counts
    /// and can bias fit parameters. The `binIndices` refer to positions in the original
    /// `BinnedCountSeries.bins` array.
    case lowCountGaussianApproximation(binIndices: [Int])

    /// The series uses the `.multinomial` observation model. The projection applies
    /// per-bin Poisson uncertainty (from `CountUncertaintyPolicy`), which does not
    /// account for the multinomial correlation structure. This is a known approximation
    /// adequate for educational use; Poisson MLE fitting is the rigorous alternative (Phase 3).
    case multinomialPoissonApproximation(allocatedCount: Int)
}

/// The result of projecting a `BinnedCountSeries` to a `FitObservationSeries`.
public struct BinnedFitProjection: Sendable {
    public let observationSeries: FitObservationSeries
    public let warnings: [BinnedFitProjectionWarning]
    public let xErrorModel: BinXErrorModel
    public let zeroBinPolicy: ZeroBinPolicy
    public let excludedBinCount: Int
}

// MARK: - Projection

extension BinnedCountSeries {
    private struct ProjectionAccumulator {
        var observations: [FitObservation] = []
        var excludedBinCount = 0
        var zeroCountKeptCount = 0
        var lowCountIndices: [Int] = []
    }

    private struct ProjectionStep {
        let observation: FitObservation?
        let excludedBinCount: Int
        let zeroCountKeptCount: Int
        let lowCountIndex: Int?
    }

    private func xStandardDeviation(for bin: CountBin, xError: BinXErrorModel) -> Double {
        switch xError {
        case .point:
            return 0
        case .uniformSpread:
            return bin.interval.width / sqrt(12)
        }
    }

    private func projectionStep(
        at index: Int,
        bin: CountBin,
        xStandardDeviation: Double,
        zeroBinPolicy: ZeroBinPolicy
    ) -> ProjectionStep {
        if bin.count == 0 {
            switch zeroBinPolicy {
            case .excludeFromProjection:
                return ProjectionStep(
                    observation: nil,
                    excludedBinCount: 1,
                    zeroCountKeptCount: 0,
                    lowCountIndex: nil
                )
            case .keepWithFallbackWarning:
                return ProjectionStep(
                    observation: FitObservation(
                        x: bin.interval.center,
                        y: 0,
                        xStandardDeviation: xStandardDeviation,
                        yStandardDeviation: uncertaintyPolicy.absoluteError(for: 0)
                    ),
                    excludedBinCount: 0,
                    zeroCountKeptCount: 1,
                    lowCountIndex: index
                )
            case .useLowCountPolicy:
                return ProjectionStep(
                    observation: FitObservation(
                        x: bin.interval.center,
                        y: 0,
                        xStandardDeviation: xStandardDeviation,
                        yStandardDeviation: CountUncertaintyPolicy.lowCountApproximation(for: 0)
                    ),
                    excludedBinCount: 0,
                    zeroCountKeptCount: 0,
                    lowCountIndex: index
                )
            }
        }

        return ProjectionStep(
            observation: FitObservation(
                x: bin.interval.center,
                y: Double(bin.count),
                xStandardDeviation: xStandardDeviation,
                yStandardDeviation: uncertaintyPolicy.absoluteError(for: bin.count)
            ),
            excludedBinCount: 0,
            zeroCountKeptCount: 0,
            lowCountIndex: bin.count < Self.lowCountGaussianWarningThreshold ? index : nil
        )
    }

    /// Counts below this threshold trigger a `.lowCountGaussianApproximation` warning.
    ///
    /// The Gaussian approximation for Poisson count uncertainty (δy = √c) is considered
    /// valid for c ≥ 20 in standard physics pedagogy. This is a pedagogical threshold,
    /// not a universal physics constant — some analyses use c ≥ 5 or c ≥ 10.
    static let lowCountGaussianWarningThreshold: Int = 20

    /// Projects this series to a `FitObservationSeries` suitable for `GaussianPeakFitter`.
    ///
    /// The bridge lives in `UncertainValueFitting` because it produces `FitObservationSeries`,
    /// a fitting type. Per bin: x = center, y = Double(count), δx per `xError` model,
    /// δy from `uncertaintyPolicy` (modified by `zeroBinPolicy` for count = 0).
    ///
    /// - Parameters:
    ///   - xError: Strategy for assigning δx. Defaults to `.point` (community standard).
    ///   - zeroBinPolicy: Required explicit policy for zero-count bins — no silent default.
    public func asFitProjection(
        xError: BinXErrorModel = .point,
        zeroBinPolicy: ZeroBinPolicy
    ) -> BinnedFitProjection {
        let projection = bins.enumerated().reduce(into: ProjectionAccumulator()) { accumulator, element in
            let (index, bin) = element
            let step = projectionStep(
                at: index,
                bin: bin,
                xStandardDeviation: xStandardDeviation(for: bin, xError: xError),
                zeroBinPolicy: zeroBinPolicy
            )

            if let observation = step.observation {
                accumulator.observations.append(observation)
            }
            accumulator.excludedBinCount += step.excludedBinCount
            accumulator.zeroCountKeptCount += step.zeroCountKeptCount
            if let lowCountIndex = step.lowCountIndex {
                accumulator.lowCountIndices.append(lowCountIndex)
            }
        }

        var warnings: [BinnedFitProjectionWarning] = []
        if projection.zeroCountKeptCount > 0 {
            warnings.append(.zeroCountBinsUseFallbackWeight(count: projection.zeroCountKeptCount))
        }
        if !projection.lowCountIndices.isEmpty {
            warnings.append(.lowCountGaussianApproximation(binIndices: projection.lowCountIndices))
        }
        if case .multinomial(let allocatedCount) = observationModel {
            warnings.append(.multinomialPoissonApproximation(allocatedCount: allocatedCount))
        }

        return BinnedFitProjection(
            observationSeries: FitObservationSeries(observations: projection.observations),
            warnings: warnings,
            xErrorModel: xError,
            zeroBinPolicy: zeroBinPolicy,
            excludedBinCount: projection.excludedBinCount
        )
    }
}
