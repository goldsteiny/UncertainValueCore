import Foundation
import Testing
@testable import UncertainValueFitting

struct GaussianPeakFitterTests {
    @Test func gaussianSpecificationRoundTripsParameterControls() throws {
        let specification = GaussianPeakSpecification(
            baseline: .fixed(1.2),
            amplitude: .seeded(3.4),
            center: .automatic,
            sigma: .bounded(initial: 0.5, lower: 0.1, upper: 2.0)
        )

        let decoded = try JSONDecoder().decode(
            GaussianPeakSpecification.self,
            from: JSONEncoder().encode(specification)
        )

        #expect(decoded == specification)
    }

    @Test func recoversSyntheticGaussianWithYErrors() {
        let observations = (-30...30).map { index in
            let x = Double(index) / 10
            let y = 1.5 + 4.0 * exp(-0.5 * pow((x - 0.7) / 0.8, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.status == .converged)
        #expect(abs(result.parameters.baseline - 1.5) < 0.05)
        #expect(abs(result.parameters.amplitude - 4.0) < 0.05)
        #expect(abs(result.parameters.center - 0.7) < 0.03)
        #expect(abs(result.parameters.sigma - 0.8) < 0.03)
    }

    @Test func recoversSmallPeakOnLargeCoordinateAndBaselineOffsets() {
        let observations = (0...80).map { index in
            let x = 1_000.0 + Double(index) * 0.05
            let y = 10_000.0 + 0.8 * exp(-0.5 * pow((x - 1_001.7) / 0.35, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.02)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.status == .converged)
        #expect(abs(result.parameters.baseline - 10_000.0) < 0.04)
        #expect(abs(result.parameters.amplitude - 0.8) < 0.04)
        #expect(abs(result.parameters.center - 1_001.7) < 0.03)
        #expect(abs(result.parameters.sigma - 0.35) < 0.03)
    }

    @Test func honorsFixedCenterAndBaseline() {
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            let y = 0.5 + 2.0 * exp(-0.5 * pow((x + 0.2) / 0.6, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(
                baseline: .fixed(0.5),
                center: .fixed(-0.2)
            )
        )

        #expect(result.status == .converged)
        #expect(result.parameters.baseline == 0.5)
        #expect(result.parameters.center == -0.2)
        #expect(abs(result.parameters.amplitude - 2.0) < 0.05)
        #expect(result.uncertainties.baseline == 0)
        #expect(result.uncertainties.center == 0)
    }

    @Test func rejectsInsufficientData() {
        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: [
                FitObservation(x: 0, y: 1),
                FitObservation(x: 1, y: 2)
            ])
        )

        #expect(result.status == .insufficientData)
    }

    @Test func acceptsXAndYUncertainties() {
        let observations = (-25...25).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 3.0 * exp(-0.5 * pow((x - 0.4) / 0.7, 2))
            return FitObservation(
                x: x,
                y: y,
                xStandardDeviation: 0.02,
                yStandardDeviation: 0.08
            )
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.status == .converged)
        #expect(result.residuals.count == observations.count)
        #expect(abs(result.parameters.center - 0.4) < 0.04)
        #expect(result.uncertainties.center != nil)
    }

    @Test func xErrorsAllowOrthogonalAdjustmentWhenCenterIsFixedOffPeak() {
        let observations = (-25...25).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 3.0 * exp(-0.5 * pow(x / 0.7, 2))
            return FitObservation(
                x: x,
                y: y,
                xStandardDeviation: 0.08,
                yStandardDeviation: 0.08
            )
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(center: .fixed(0.12))
        )

        #expect(result.status == .converged)
        #expect(result.parameters.center == 0.12)
        #expect(result.residuals.contains { abs($0.xResidual) > 1e-5 })
    }

    @Test func dropsNonFiniteObservationsAndReportsWarning() {
        let observations = (-20...20).map { index -> FitObservation in
            if index == 0 {
                return FitObservation(x: .nan, y: 1)
            }
            let x = Double(index) / 10
            let y = 1.0 + 2.0 * exp(-0.5 * pow(x / 0.5, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.1)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.observationsDropped == 1)
        #expect(result.warnings.contains(.droppedNonFinitePoints(1)))
        #expect(result.status == .converged)
    }

    @Test func honorsSelectedXRange() {
        let observations = (-30...30).map { index in
            let x = Double(index) / 10
            let y = 0.5 + 5.0 * exp(-0.5 * pow((x - 0.2) / 0.45, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            xRange: -0.8...1.2
        )

        #expect(result.status == .converged)
        #expect(result.observationsUsed == observations.filter { (-0.8...1.2).contains($0.x) }.count)
        #expect(abs(result.parameters.center - 0.2) < 0.04)
    }

    @Test func fitsNegativeAmplitudePeak() {
        let observations = (-30...30).map { index in
            let x = Double(index) / 10
            let y = 3.0 - 1.7 * exp(-0.5 * pow((x + 0.5) / 0.6, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.status == .converged)
        #expect(result.parameters.amplitude < 0)
        #expect(abs(result.parameters.center + 0.5) < 0.04)
    }

    @Test func boundedSigmaReportsBoundWarning() {
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 2.0 * exp(-0.5 * pow(x / 0.7, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(
                sigma: .bounded(initial: 0.3, lower: 0.3, upper: 0.3)
            )
        )

        #expect(abs(result.parameters.sigma - 0.3) < 1e-8)
        #expect(result.warnings.contains(.sigmaAtBound))
    }

    @Test func sigmaRemainsPositiveForInvalidUserSeed() {
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 2.0 * exp(-0.5 * pow(x / 0.7, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(sigma: .seeded(-1))
        )

        #expect(result.parameters.sigma > 0)
        #expect(result.parameters.sigma.isFinite)
    }

    @Test func honorsFixedAmplitudeAndSigma() {
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            let y = 0.8 + 2.4 * exp(-0.5 * pow((x - 0.2) / 0.55, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(
                amplitude: .fixed(2.4),
                sigma: .fixed(0.55)
            )
        )

        #expect(result.status == .converged)
        #expect(result.parameters.amplitude == 2.4)
        #expect(result.parameters.sigma == 0.55)
        #expect(abs(result.parameters.center - 0.2) < 0.04)
        #expect(result.uncertainties.amplitude == 0)
        #expect(result.uncertainties.sigma == 0)
    }

    @Test func reportsInsufficientDegreesOfFreedomForExactFreeParameterCount() {
        let observations = (0..<4).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 2.0 * exp(-0.5 * pow((x - 0.1) / 0.5, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.degreesOfFreedom == 0)
        #expect(result.reducedChiSquare == nil)
        #expect(result.uncertainties.center == nil)
        #expect(result.warnings.contains(.insufficientDegreesOfFreedom))
        #expect(result.warnings.contains(.covarianceUnavailable))
    }

    @Test func reportsMaxIterationsWhenIterationBudgetIsExhausted() {
        let observations = (-30...30).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 5.0 * exp(-0.5 * pow((x - 0.8) / 0.4, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter(
            options: GaussianPeakFitter.Options(maximumIterations: 0)
        ).fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(
                baseline: .seeded(4),
                amplitude: .seeded(0.5),
                center: .seeded(-1.5),
                sigma: .seeded(1.5)
            )
        )

        #expect(result.status == .maxIterations)
        #expect(result.iterations == 0)
    }

    @Test func allFixedParametersReturnZeroUncertainties() {
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 2.0 * exp(-0.5 * pow((x - 0.1) / 0.5, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(
                baseline: .fixed(1.0),
                amplitude: .fixed(2.0),
                center: .fixed(0.1),
                sigma: .fixed(0.5)
            )
        )

        #expect(result.status == .converged)
        #expect(result.uncertainties.baseline == 0)
        #expect(result.uncertainties.amplitude == 0)
        #expect(result.uncertainties.center == 0)
        #expect(result.uncertainties.sigma == 0)
    }

    @Test func unweightedFitHandlesZeroErrors() {
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            let y = 2.0 + 1.5 * exp(-0.5 * pow((x - 0.3) / 0.4, 2))
            return FitObservation(x: x, y: y)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.status == .converged)
        #expect(abs(result.parameters.center - 0.3) < 0.04)
    }

    @Test func sparseTailFitIsNotHorizontallyShiftedIntoWorseLocalBasin() {
        let trueParameters = GaussianPeakParameters(
            baseline: 0.8,
            amplitude: 4.2,
            center: -0.15,
            sigma: 0.55
        )
        let observations = [0.30, 0.48, 0.68, 0.90].map { x in
            FitObservation(
                x: x,
                y: gaussian(x: x, parameters: trueParameters),
                xStandardDeviation: 0.03,
                yStandardDeviation: 0.06
            )
        }
        let series = FitObservationSeries(observations: observations)

        let result = GaussianPeakFitter().fit(series: series)
        let objective = GaussianFitObjective.weightedObjective(series: series, parameters: result.parameters)
        let shiftedLeft = GaussianPeakParameters(
            baseline: result.parameters.baseline,
            amplitude: result.parameters.amplitude,
            center: result.parameters.center - 0.03,
            sigma: result.parameters.sigma
        )
        let shiftedRight = GaussianPeakParameters(
            baseline: result.parameters.baseline,
            amplitude: result.parameters.amplitude,
            center: result.parameters.center + 0.03,
            sigma: result.parameters.sigma
        )

        #expect(result.status == .converged)
        #expect(result.parameters.center < observations.map(\.x).min()!)
        #expect(objective <= GaussianFitObjective.weightedObjective(series: series, parameters: shiftedLeft) + 1e-6)
        #expect(objective <= GaussianFitObjective.weightedObjective(series: series, parameters: shiftedRight) + 1e-6)
    }

    @Test func multiStartEscapesBadSeededStartingPoint() {
        let trueParameters = GaussianPeakParameters(
            baseline: 1.2,
            amplitude: 3.5,
            center: -0.35,
            sigma: 0.42
        )
        let observations = (-20...20).map { index in
            let x = Double(index) / 10
            return FitObservation(
                x: x,
                y: gaussian(x: x, parameters: trueParameters),
                yStandardDeviation: 0.04
            )
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations),
            specification: GaussianPeakSpecification(
                baseline: .seeded(4.0),
                amplitude: .seeded(0.2),
                center: .seeded(1.4),
                sigma: .seeded(1.5)
            )
        )

        #expect(result.status == .converged)
        #expect(abs(result.parameters.center - trueParameters.center) < 0.05)
        #expect(abs(result.parameters.sigma - trueParameters.sigma) < 0.06)
    }

    @Test func weaklyConstrainedFitReportsWarning() {
        let observations = (0..<4).map { index in
            let x = Double(index) / 10
            let y = 1.0 + 2.0 * exp(-0.5 * pow((x - 0.1) / 0.5, 2))
            return FitObservation(x: x, y: y, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter().fit(
            series: FitObservationSeries(observations: observations)
        )

        #expect(result.warnings.contains(.weaklyConstrainedFit))
    }

    @Test func startCandidateCapDoesNotPreventTypicalConvergence() {
        let observations = (-25...25).map { index in
            let x = Double(index) / 10
            let y = 0.9 + 2.8 * exp(-0.5 * pow((x - 0.45) / 0.5, 2))
            return FitObservation(x: x, y: y, xStandardDeviation: 0.02, yStandardDeviation: 0.05)
        }

        let result = GaussianPeakFitter(
            options: GaussianPeakFitter.Options(maximumStartCandidates: 8)
        ).fit(series: FitObservationSeries(observations: observations))

        #expect(result.status == .converged)
        #expect(abs(result.parameters.center - 0.45) < 0.05)
    }

    private func gaussian(x: Double, parameters: GaussianPeakParameters) -> Double {
        parameters.baseline
            + parameters.amplitude * exp(-0.5 * pow((x - parameters.center) / parameters.sigma, 2))
    }
}
