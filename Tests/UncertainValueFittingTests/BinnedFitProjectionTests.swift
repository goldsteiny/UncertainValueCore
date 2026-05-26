import Foundation
import Testing
@testable import UncertainValueFitting
import UncertainValueBinning

private func makeSeries(
    counts: [Int],
    startValue: Double = 0,
    binWidth: Double = 1,
    policy: CountUncertaintyPolicy = CountUncertaintyPolicy(),
    model: CountObservationModel = .poisson
) throws -> BinnedCountSeries {
    try BinnedCountSeries(
        counts: counts,
        startValue: startValue,
        binWidth: binWidth,
        policy: policy,
        model: model
    )
}

private func approxEqual(_ a: Double, _ b: Double, eps: Double = 1e-12) -> Bool {
    abs(a - b) < eps
}

struct BinnedFitProjectionTests {

    // MARK: - x-error models

    @Test func pointXErrorModelProducesZeroXSD() throws {
        let series = try makeSeries(counts: [10, 20, 30])
        let projection = series.asFitProjection(xError: .point, zeroBinPolicy: .excludeFromProjection)
        for obs in projection.observationSeries.observations {
            #expect(obs.xStandardDeviation == 0)
        }
    }

    @Test func uniformSpreadXErrorModelProducesWidthOverSqrt12() throws {
        let binWidth = 2.0
        let series = try makeSeries(counts: [10, 20, 30], binWidth: binWidth)
        let projection = series.asFitProjection(xError: .uniformSpread, zeroBinPolicy: .excludeFromProjection)
        let expected = binWidth / sqrt(12)
        for obs in projection.observationSeries.observations {
            #expect(approxEqual(obs.xStandardDeviation, expected))
        }
    }

    @Test func uniformSpreadDependsOnBinWidth() throws {
        // Non-uniform bins → different xSD per bin
        let series = try BinnedCountSeries(
            edges: [0, 1, 3, 6],
            counts: [10, 10, 10],
            policy: CountUncertaintyPolicy(),
            model: .poisson
        )
        let projection = series.asFitProjection(xError: .uniformSpread, zeroBinPolicy: .excludeFromProjection)
        let obs = projection.observationSeries.observations
        // Bin widths: 1, 2, 3 → xSD: 1/√12, 2/√12, 3/√12
        #expect(approxEqual(obs[0].xStandardDeviation, 1.0 / sqrt(12)))
        #expect(approxEqual(obs[1].xStandardDeviation, 2.0 / sqrt(12)))
        #expect(approxEqual(obs[2].xStandardDeviation, 3.0 / sqrt(12)))
    }

    @Test func defaultXErrorModelIsPoint() throws {
        let series = try makeSeries(counts: [10])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.xErrorModel == .point)
        #expect(projection.observationSeries.observations[0].xStandardDeviation == 0)
    }

    // MARK: - x positions (bin centers)

    @Test func xValuesAreBinCenters() throws {
        let series = try makeSeries(counts: [5, 10])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(approxEqual(projection.observationSeries.observations[0].x, 0.5))
        #expect(approxEqual(projection.observationSeries.observations[1].x, 1.5))
    }

    @Test func xValuesForNonZeroStartValue() throws {
        let series = try makeSeries(counts: [5, 10], startValue: 100, binWidth: 2)
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(approxEqual(projection.observationSeries.observations[0].x, 101.0))
        #expect(approxEqual(projection.observationSeries.observations[1].x, 103.0))
    }

    // MARK: - y values

    @Test func yValuesAreDoubleOfCount() throws {
        let series = try makeSeries(counts: [3, 7, 42])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let obs = projection.observationSeries.observations
        #expect(obs[0].y == 3.0)
        #expect(obs[1].y == 7.0)
        #expect(obs[2].y == 42.0)
    }

    @Test func yUncertaintyUsesPolicy() throws {
        let policy = CountUncertaintyPolicy()
        let series = try makeSeries(counts: [4, 9, 16, 25], policy: policy)
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let obs = projection.observationSeries.observations
        #expect(approxEqual(obs[0].yStandardDeviation, 2.0))  // √4
        #expect(approxEqual(obs[1].yStandardDeviation, 3.0))  // √9
        #expect(approxEqual(obs[2].yStandardDeviation, 4.0))  // √16
        #expect(approxEqual(obs[3].yStandardDeviation, 5.0))  // √25
    }

    @Test func yUncertaintyUsesLowCountPolicyWhenThresholdSet() throws {
        let policy = CountUncertaintyPolicy(threshold: 10)
        let series = try makeSeries(counts: [3], policy: policy)
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let expected = CountUncertaintyPolicy.lowCountApproximation(for: 3)
        #expect(approxEqual(projection.observationSeries.observations[0].yStandardDeviation, expected))
    }

    // MARK: - ZeroBinPolicy: excludeFromProjection

    @Test func excludeFromProjectionDropsZeroCountBins() throws {
        let series = try makeSeries(counts: [5, 0, 10])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.count == 2)
        #expect(projection.excludedBinCount == 1)
    }

    @Test func excludeFromProjectionDropsAllZeroCountBins() throws {
        let series = try makeSeries(counts: [0, 0, 0])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.isEmpty)
        #expect(projection.excludedBinCount == 3)
    }

    @Test func excludeFromProjectionDropsMultipleZeroBins() throws {
        let series = try makeSeries(counts: [0, 5, 0, 0, 10, 0])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.count == 2)
        #expect(projection.excludedBinCount == 4)
    }

    @Test func excludeFromProjectionEmitsNoZeroCountWarning() throws {
        let series = try makeSeries(counts: [25, 0, 30])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasZeroWarning = projection.warnings.contains {
            if case .zeroCountBinsUseFallbackWeight = $0 { return true }
            return false
        }
        #expect(hasZeroWarning == false)
    }

    @Test func excludeFromProjectionKeepsNonZeroBinY() throws {
        let series = try makeSeries(counts: [0, 7, 0])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.count == 1)
        #expect(projection.observationSeries.observations[0].y == 7.0)
    }

    @Test func excludeFromProjectionWithNoZeroBinsHasZeroExcludedCount() throws {
        let series = try makeSeries(counts: [5, 10, 15])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.excludedBinCount == 0)
    }

    // MARK: - ZeroBinPolicy: keepWithFallbackWarning

    @Test func keepWithFallbackWarningIncludesZeroCountBins() throws {
        let series = try makeSeries(counts: [5, 0, 10])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        #expect(projection.observationSeries.observations.count == 3)
        #expect(projection.excludedBinCount == 0)
    }

    @Test func keepWithFallbackWarningEmitsWarningWithCorrectCount() throws {
        let series = try makeSeries(counts: [5, 0, 0, 10])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        let warning = projection.warnings.first {
            if case .zeroCountBinsUseFallbackWeight = $0 { return true }
            return false
        }
        guard case .zeroCountBinsUseFallbackWeight(let count) = warning else {
            Issue.record("Expected zeroCountBinsUseFallbackWeight warning")
            return
        }
        #expect(count == 2)
    }

    @Test func keepWithFallbackWarningZeroBinHasYEqualsZero() throws {
        let series = try makeSeries(counts: [0])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        #expect(projection.observationSeries.observations[0].y == 0)
    }

    @Test func keepWithFallbackWarningZeroBinYSDFromPolicy() throws {
        // Default policy, count=0 → sqrt(0) = 0
        let series = try makeSeries(counts: [0])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        #expect(projection.observationSeries.observations[0].yStandardDeviation == 0)
    }

    @Test func keepWithFallbackWarningWithThresholdPolicyYSDIsNonZero() throws {
        // With threshold policy, count=0 uses low-count formula → ~1.87
        let policy = CountUncertaintyPolicy(threshold: 10)
        let series = try makeSeries(counts: [0], policy: policy)
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        let expected = CountUncertaintyPolicy.lowCountApproximation(for: 0)
        #expect(approxEqual(projection.observationSeries.observations[0].yStandardDeviation, expected))
    }

    @Test func keepWithFallbackWarningNoWarningWhenNoZeroBins() throws {
        let series = try makeSeries(counts: [25, 30, 25])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        let hasZeroWarning = projection.warnings.contains {
            if case .zeroCountBinsUseFallbackWeight = $0 { return true }
            return false
        }
        #expect(hasZeroWarning == false)
    }

    @Test func keepWithFallbackWarningCountMatchesZeroBinCount() throws {
        let series = try makeSeries(counts: [0, 0, 0, 0, 0])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        let warning = projection.warnings.first {
            if case .zeroCountBinsUseFallbackWeight = $0 { return true }
            return false
        }
        guard case .zeroCountBinsUseFallbackWeight(let count) = warning else {
            Issue.record("Expected warning")
            return
        }
        #expect(count == 5)
    }

    // MARK: - ZeroBinPolicy: useLowCountPolicy

    @Test func useLowCountPolicyAppliesGehrelFormulaToZeroBins() throws {
        let series = try makeSeries(counts: [0])
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        let expected = CountUncertaintyPolicy.lowCountApproximation(for: 0)
        #expect(approxEqual(projection.observationSeries.observations[0].yStandardDeviation, expected))
    }

    @Test func useLowCountPolicyGehrelValueIsApproximately187() throws {
        let series = try makeSeries(counts: [0])
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        let ySD = projection.observationSeries.observations[0].yStandardDeviation
        #expect(approxEqual(ySD, 1.0 + sqrt(0.75), eps: 1e-10))
    }

    @Test func useLowCountPolicyIncludesZeroBins() throws {
        let series = try makeSeries(counts: [5, 0, 10])
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        #expect(projection.observationSeries.observations.count == 3)
        #expect(projection.excludedBinCount == 0)
    }

    @Test func useLowCountPolicyDoesNotOverrideNonZeroBinsWithDefaultPolicy() throws {
        let series = try makeSeries(counts: [25, 0])
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        // count=25 with default policy (no threshold) uses sqrt(25) = 5
        #expect(approxEqual(projection.observationSeries.observations[0].yStandardDeviation, 5.0))
    }

    @Test func useLowCountPolicyDoesNotOverrideNonZeroBinsWithThresholdPolicy() throws {
        let policy = CountUncertaintyPolicy(threshold: 30)
        let series = try makeSeries(counts: [5, 0], policy: policy)
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        // count=5 < threshold=30 → uses low-count formula from policy
        let expected = CountUncertaintyPolicy.lowCountApproximation(for: 5)
        #expect(approxEqual(projection.observationSeries.observations[0].yStandardDeviation, expected))
    }

    @Test func useLowCountPolicyEmitsNoZeroCountFallbackWarning() throws {
        let series = try makeSeries(counts: [0, 5])
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        let hasZeroWarning = projection.warnings.contains {
            if case .zeroCountBinsUseFallbackWeight = $0 { return true }
            return false
        }
        #expect(hasZeroWarning == false)
    }

    // MARK: - Low-count Gaussian approximation warning

    @Test func lowCountWarningFiresForCount19() throws {
        let series = try makeSeries(counts: [19])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == true)
    }

    @Test func lowCountWarningDoesNotFireForCount20() throws {
        let series = try makeSeries(counts: [20])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == false)
    }

    @Test func lowCountWarningDoesNotFireForCount21() throws {
        let series = try makeSeries(counts: [21])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == false)
    }

    @Test func lowCountWarningDoesNotFireForCount100() throws {
        let series = try makeSeries(counts: [100])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == false)
    }

    @Test func lowCountWarningFiresForCount1() throws {
        let series = try makeSeries(counts: [1])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == true)
    }

    @Test func lowCountWarningIncludesCorrectBinIndices() throws {
        // bins: [5, 25, 3] — indices 0 and 2 are below threshold 20
        let series = try makeSeries(counts: [5, 25, 3])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let warning = projection.warnings.first {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        guard case .lowCountGaussianApproximation(let indices) = warning else {
            Issue.record("Expected lowCountGaussianApproximation warning")
            return
        }
        #expect(indices == [0, 2])
    }

    @Test func lowCountWarningUsesOriginalIndicesEvenWhenSomeBinsExcluded() throws {
        // bins: [0, 5, 25] — index 0 excluded, index 1 is low-count (original index 1)
        let series = try makeSeries(counts: [0, 5, 25])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let warning = projection.warnings.first {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        guard case .lowCountGaussianApproximation(let indices) = warning else {
            Issue.record("Expected lowCountGaussianApproximation warning")
            return
        }
        #expect(indices == [1])  // original index 1, not post-exclusion index 0
    }

    @Test func zeroCountKeptBinIsAlsoLowCountWarning() throws {
        // count=0 < 20 → both zeroCountBinsUseFallbackWeight and lowCountGaussianApproximation
        let series = try makeSeries(counts: [0])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        let hasZeroWarning = projection.warnings.contains {
            if case .zeroCountBinsUseFallbackWeight = $0 { return true }
            return false
        }
        let hasLowCountWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasZeroWarning == true)
        #expect(hasLowCountWarning == true)
    }

    @Test func noLowCountWarningWhenAllBinsAtOrAboveThreshold() throws {
        let series = try makeSeries(counts: [20, 30, 100, 20])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasLowCountWarning = projection.warnings.contains {
            if case .lowCountGaussianApproximation = $0 { return true }
            return false
        }
        #expect(hasLowCountWarning == false)
    }

    // MARK: - Multinomial Poisson approximation warning

    @Test func multinomialModelFiresApproximationWarning() throws {
        let series = try makeSeries(counts: [25, 30, 25], model: .multinomial(allocatedCount: 80))
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let warning = projection.warnings.first {
            if case .multinomialPoissonApproximation = $0 { return true }
            return false
        }
        guard case .multinomialPoissonApproximation(let allocatedCount) = warning else {
            Issue.record("Expected multinomialPoissonApproximation warning")
            return
        }
        #expect(allocatedCount == 80)
    }

    @Test func poissonModelDoesNotFireMultinomialWarning() throws {
        let series = try makeSeries(counts: [25, 30, 25], model: .poisson)
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .multinomialPoissonApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == false)
    }

    @Test func multinomialWarningAlwaysFiresEvenWithHighCounts() throws {
        // Even when Gaussian approx is valid (all counts >= 20), multinomial still warns
        let series = try makeSeries(counts: [50, 50, 50], model: .multinomial(allocatedCount: 150))
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        let hasWarning = projection.warnings.contains {
            if case .multinomialPoissonApproximation = $0 { return true }
            return false
        }
        #expect(hasWarning == true)
    }

    // MARK: - Multiple simultaneous warnings

    @Test func allThreeWarningsCanFireTogether() throws {
        // multinomial model + zero bins (kept) + low-count bins
        let series = try makeSeries(
            counts: [0, 5, 25],
            model: .multinomial(allocatedCount: 30)
        )
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        let warningTypes = Set(projection.warnings.map { w -> String in
            switch w {
            case .zeroCountBinsUseFallbackWeight: return "zero"
            case .lowCountGaussianApproximation: return "lowCount"
            case .multinomialPoissonApproximation: return "multinomial"
            }
        })
        #expect(warningTypes == ["zero", "lowCount", "multinomial"])
    }

    @Test func onlyMultinomialWarningWhenAllBinsAboveThresholdNoZeros() throws {
        let series = try makeSeries(
            counts: [50, 60, 40],
            model: .multinomial(allocatedCount: 150)
        )
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.warnings.count == 1)
        if case .multinomialPoissonApproximation = projection.warnings[0] {
            // correct
        } else {
            Issue.record("Expected only multinomialPoissonApproximation warning")
        }
    }

    @Test func noWarningsForIdealHighCountPoissonSeries() throws {
        let series = try makeSeries(counts: [100, 200, 150, 300])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.warnings.isEmpty)
    }

    // MARK: - Projection metadata

    @Test func projectionCarriesXErrorModelPoint() throws {
        let series = try makeSeries(counts: [10])
        let projection = series.asFitProjection(xError: .point, zeroBinPolicy: .excludeFromProjection)
        #expect(projection.xErrorModel == .point)
    }

    @Test func projectionCarriesXErrorModelUniformSpread() throws {
        let series = try makeSeries(counts: [10])
        let projection = series.asFitProjection(xError: .uniformSpread, zeroBinPolicy: .excludeFromProjection)
        #expect(projection.xErrorModel == .uniformSpread)
    }

    @Test func projectionCarriesZeroBinPolicyExclude() throws {
        let series = try makeSeries(counts: [10])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.zeroBinPolicy == .excludeFromProjection)
    }

    @Test func projectionCarriesZeroBinPolicyKeep() throws {
        let series = try makeSeries(counts: [10])
        let projection = series.asFitProjection(zeroBinPolicy: .keepWithFallbackWarning)
        #expect(projection.zeroBinPolicy == .keepWithFallbackWarning)
    }

    @Test func projectionCarriesZeroBinPolicyUseLowCount() throws {
        let series = try makeSeries(counts: [10])
        let projection = series.asFitProjection(zeroBinPolicy: .useLowCountPolicy)
        #expect(projection.zeroBinPolicy == .useLowCountPolicy)
    }

    @Test func projectionObservationCountMatchesNonExcludedBins() throws {
        let series = try makeSeries(counts: [10, 0, 20, 0, 30])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.count == 3)
        #expect(projection.excludedBinCount + projection.observationSeries.observations.count == series.count)
    }

    // MARK: - Single-bin edge cases

    @Test func singleNonZeroBinProjectsCorrectly() throws {
        let series = try makeSeries(counts: [42])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.count == 1)
        #expect(projection.observationSeries.observations[0].y == 42)
        #expect(projection.excludedBinCount == 0)
        #expect(projection.warnings.contains { if case .lowCountGaussianApproximation = $0 { return true }; return false } == false)
    }

    @Test func singleZeroBinExcludesEverything() throws {
        let series = try makeSeries(counts: [0])
        let projection = series.asFitProjection(zeroBinPolicy: .excludeFromProjection)
        #expect(projection.observationSeries.observations.isEmpty)
        #expect(projection.excludedBinCount == 1)
    }

    // MARK: - Threshold constant

    @Test func lowCountGaussianWarningThresholdIs20() {
        #expect(BinnedCountSeries.lowCountGaussianWarningThreshold == 20)
    }

    @Test func boundaryBelow20IsBelowThreshold() {
        #expect(19 < BinnedCountSeries.lowCountGaussianWarningThreshold)
    }

    @Test func boundaryAt20IsNotBelow() {
        #expect(!(20 < BinnedCountSeries.lowCountGaussianWarningThreshold))
    }
}
