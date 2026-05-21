//
//  GaussianPeakFitter.swift
//  UncertainValueFitting
//
//  Scoped Gaussian peak fitting with x/y-error orthogonal residuals.
//

import Foundation

public struct GaussianPeakFitter: Sendable {
    public struct Options: Codable, Hashable, Sendable {
        public var maximumIterations: Int
        public var convergenceTolerance: Double
        public var initialDamping: Double
        public var maximumDamping: Double

        public init(
            maximumIterations: Int = 80,
            convergenceTolerance: Double = 1e-8,
            initialDamping: Double = 1e-3,
            maximumDamping: Double = 1e12
        ) {
            self.maximumIterations = maximumIterations
            self.convergenceTolerance = convergenceTolerance
            self.initialDamping = initialDamping
            self.maximumDamping = maximumDamping
        }
    }

    public let options: Options

    public init(options: Options = Options()) {
        self.options = options
    }

    public func fit(
        series: FitObservationSeries,
        specification: GaussianPeakSpecification = .automatic,
        xRange: ClosedRange<Double>? = nil
    ) -> GaussianPeakFitResult {
        let selected = series.filtered(to: xRange)
        let finiteObservations = selected.observations.filter(\.isFinite)
        let droppedCount = selected.observations.count - finiteObservations.count

        guard finiteObservations.count >= 3 else {
            return emptyResult(status: .insufficientData, droppedCount: droppedCount)
        }

        let scale = FitScale(observations: finiteObservations)
        let observations = finiteObservations.map(scale.scaledObservation)
        let scaledSpecification = scale.scaledSpecification(specification)
        let defaults = WorkingParameters.estimate(from: observations)
        let controls = ParameterControls(specification: scaledSpecification, defaults: defaults)
        var current = controls.initialParameters

        guard current.isFinite, controls.freeParameterCount <= observations.count else {
            return emptyResult(status: .insufficientData, droppedCount: droppedCount)
        }

        var damping = options.initialDamping
        var status: FitConvergenceStatus = .maxIterations
        var iterations = 0
        var currentEvaluation = Evaluation(parameters: current, observations: observations)

        for iteration in 0..<options.maximumIterations {
            iterations = iteration + 1
            guard let step = makeStep(
                parameters: current,
                controls: controls,
                evaluation: currentEvaluation,
                damping: damping
            ) else {
                status = .singularSystem
                break
            }

            let stepNorm = step.map(abs).max() ?? 0
            if stepNorm < options.convergenceTolerance {
                status = .converged
                break
            }

            let trial = controls.applying(step: step, to: current)
            let trialEvaluation = Evaluation(parameters: trial, observations: observations)

            if trialEvaluation.objective < currentEvaluation.objective {
                let improvement = currentEvaluation.objective - trialEvaluation.objective
                current = trial
                currentEvaluation = trialEvaluation
                damping = max(damping / 3, 1e-12)

                let relativeImprovement = improvement / max(currentEvaluation.objective, 1)
                if relativeImprovement < options.convergenceTolerance {
                    status = .converged
                    break
                }
            } else {
                damping *= 10
                if damping > options.maximumDamping {
                    status = .singularSystem
                    break
                }
            }
        }

        let finalEvaluation = Evaluation(parameters: current, observations: observations)
        let covarianceResult = covariance(
            parameters: current,
            controls: controls,
            evaluation: finalEvaluation
        )

        var warnings = covarianceResult.warnings
        if droppedCount > 0 {
            warnings.append(.droppedNonFinitePoints(droppedCount))
        }
        if controls.isSigmaAtBound(current) {
            warnings.append(.sigmaAtBound)
        }
        if finalEvaluation.hasHighOrthogonalAdjustment {
            warnings.append(.highOrthogonalAdjustment)
        }

        let rawParameters = scale.rawParameters(current.rawValue)
        let rawUncertainties = scale.rawUncertainties(
            scaledParameters: current.rawValue,
            scaledUncertainties: covarianceResult.uncertainties,
            fixedParameters: controls.fixedParameters
        )

        return GaussianPeakFitResult(
            parameters: rawParameters,
            uncertainties: rawUncertainties,
            covariance: covarianceResult.rawCovariance.map(scale.rawCovariance),
            residuals: finalEvaluation.residuals.map(scale.rawResidual),
            observationsUsed: observations.count,
            observationsDropped: droppedCount,
            degreesOfFreedom: covarianceResult.degreesOfFreedom,
            reducedChiSquare: covarianceResult.reducedChiSquare,
            iterations: iterations,
            status: status,
            warnings: warnings.uniquePreservingOrder
        )
    }
}

private extension GaussianPeakFitter {
    func emptyResult(status: FitConvergenceStatus, droppedCount: Int) -> GaussianPeakFitResult {
        GaussianPeakFitResult(
            parameters: GaussianPeakParameters(baseline: 0, amplitude: 0, center: 0, sigma: 1),
            uncertainties: .unavailable,
            covariance: nil,
            residuals: [],
            observationsUsed: 0,
            observationsDropped: droppedCount,
            degreesOfFreedom: 0,
            reducedChiSquare: nil,
            iterations: 0,
            status: status,
            warnings: [.covarianceUnavailable]
        )
    }

    func makeStep(
        parameters: WorkingParameters,
        controls: ParameterControls,
        evaluation: Evaluation,
        damping: Double
    ) -> [Double]? {
        let freeParameters = controls.freeParameters
        guard !freeParameters.isEmpty else { return [] }

        var normal = Array(
            repeating: Array(repeating: 0.0, count: freeParameters.count),
            count: freeParameters.count
        )
        var rhs = Array(repeating: 0.0, count: freeParameters.count)

        for point in evaluation.adjustedPoints {
            let derivatives = parameters.derivatives(at: point.xAdjusted)
            let residual = point.yResidual / point.yScale
            let row = freeParameters.map { parameter in
                derivatives.derivative(for: parameter) / point.yScale
            }

            for i in row.indices {
                rhs[i] += row[i] * residual
                for j in row.indices {
                    normal[i][j] += row[i] * row[j]
                }
            }
        }

        for i in normal.indices {
            normal[i][i] += damping * max(normal[i][i], 1)
        }

        return SmallLinearAlgebra.solve(normal, rhs)
    }

    func covariance(
        parameters: WorkingParameters,
        controls: ParameterControls,
        evaluation: Evaluation
    ) -> CovarianceResult {
        let freeParameters = controls.freeParameters
        let residualComponentCount = evaluation.residualComponentCount
        let degreesOfFreedom = residualComponentCount - freeParameters.count
        guard degreesOfFreedom > 0 else {
            return CovarianceResult(
                uncertainties: .unavailable,
                rawCovariance: nil,
                reducedChiSquare: nil,
                degreesOfFreedom: degreesOfFreedom,
                warnings: [.insufficientDegreesOfFreedom, .covarianceUnavailable]
            )
        }

        guard !freeParameters.isEmpty else {
            return CovarianceResult(
                uncertainties: GaussianPeakParameterUncertainties(
                    baseline: 0,
                    amplitude: 0,
                    center: 0,
                    sigma: 0,
                    peakY: 0,
                    area: 0,
                    fwhm: 0
                ),
                rawCovariance: Array(repeating: Array(repeating: 0, count: 4), count: 4),
                reducedChiSquare: evaluation.objective / Double(degreesOfFreedom),
                degreesOfFreedom: degreesOfFreedom,
                warnings: []
            )
        }

        let normal = residualNormalMatrix(
            parameters: parameters,
            controls: controls,
            evaluation: evaluation
        )

        guard let inverse = SmallLinearAlgebra.inverse(normal) else {
            return CovarianceResult(
                uncertainties: .unavailable,
                rawCovariance: nil,
                reducedChiSquare: evaluation.objective / Double(degreesOfFreedom),
                degreesOfFreedom: degreesOfFreedom,
                warnings: [.covarianceUnavailable]
            )
        }

        let reducedChiSquare = evaluation.objective / Double(degreesOfFreedom)
        let covariance = inverse.map { row in row.map { $0 * reducedChiSquare } }
        let expanded = controls.sigmaTransformedCovariance(
            parameters: parameters,
            covariance: controls.expandedCovariance(covariance)
        )
        let uncertainties = controls.uncertainties(
            parameters: parameters,
            covariance: expanded
        )
        let warnings: [FitQualityWarning] = SmallLinearAlgebra.isIllConditioned(normal)
            ? [.illConditionedCovariance]
            : []

        return CovarianceResult(
            uncertainties: uncertainties,
            rawCovariance: expanded,
            reducedChiSquare: reducedChiSquare,
            degreesOfFreedom: degreesOfFreedom,
            warnings: warnings
        )
    }

    func residualNormalMatrix(
        parameters: WorkingParameters,
        controls: ParameterControls,
        evaluation: Evaluation
    ) -> [[Double]] {
        let freeParameters = controls.freeParameters
        let baseVector = evaluation.weightedResidualVector
        let columns = freeParameters.enumerated().map { index, parameter in
            let value = controls.value(for: parameter, in: parameters)
            let epsilon = 1e-5 * max(abs(value), 1)
            var step = Array(repeating: 0.0, count: freeParameters.count)
            step[index] = epsilon
            let perturbed = controls.applying(step: step, to: parameters)
            let actualDelta = controls.value(for: parameter, in: perturbed) - value
            guard abs(actualDelta) > 1e-12 else {
                return Array(repeating: 0.0, count: baseVector.count)
            }
            let perturbedVector = Evaluation(
                parameters: perturbed,
                observations: evaluation.observations
            ).weightedResidualVector
            return zip(perturbedVector, baseVector).map { ($0 - $1) / actualDelta }
        }

        return freeParameters.indices.map { row in
            freeParameters.indices.map { column in
                zip(columns[row], columns[column]).reduce(0.0) { partial, values in
                    partial + values.0 * values.1
                }
            }
        }
    }
}

private struct CovarianceResult {
    let uncertainties: GaussianPeakParameterUncertainties
    let rawCovariance: [[Double]]?
    let reducedChiSquare: Double?
    let degreesOfFreedom: Int
    let warnings: [FitQualityWarning]
}

private struct ScaledObservation {
    let x: Double
    let y: Double
    let xStandardDeviation: Double
    let yStandardDeviation: Double
}

private struct FitScale {
    private static let minimumPositiveScale = 1e-12

    let xOffset: Double
    let xScale: Double
    let yOffset: Double
    let yScale: Double

    init(observations: [FitObservation]) {
        let xs = observations.map(\.x)
        let ys = observations.map(\.y)
        let xMin = xs.min() ?? 0
        let xMax = xs.max() ?? 1
        let yMin = ys.min() ?? 0
        let yMax = ys.max() ?? 1

        xOffset = (xMin + xMax) / 2
        xScale = Self.scale(span: xMax - xMin, fallbackOffset: xOffset)
        yOffset = (yMin + yMax) / 2
        yScale = Self.scale(span: yMax - yMin, fallbackOffset: yOffset)
    }

    private static func scale(span: Double, fallbackOffset: Double) -> Double {
        if span.isFinite, span > minimumPositiveScale { return span }
        return max(abs(fallbackOffset), 1)
    }

    func scaledObservation(_ observation: FitObservation) -> ScaledObservation {
        ScaledObservation(
            x: (observation.x - xOffset) / xScale,
            y: (observation.y - yOffset) / yScale,
            xStandardDeviation: observation.xStandardDeviation / xScale,
            yStandardDeviation: observation.yStandardDeviation / yScale
        )
    }

    func scaledSpecification(_ specification: GaussianPeakSpecification) -> GaussianPeakSpecification {
        GaussianPeakSpecification(
            baseline: specification.baseline.scaled(offset: yOffset, scale: yScale),
            amplitude: specification.amplitude.scaled(scale: yScale),
            center: specification.center.scaled(offset: xOffset, scale: xScale),
            sigma: specification.sigma.scaled(scale: xScale)
        )
    }

    func rawParameters(_ parameters: GaussianPeakParameters) -> GaussianPeakParameters {
        GaussianPeakParameters(
            baseline: yOffset + parameters.baseline * yScale,
            amplitude: parameters.amplitude * yScale,
            center: xOffset + parameters.center * xScale,
            sigma: parameters.sigma * xScale
        )
    }

    func rawUncertainties(
        scaledParameters: GaussianPeakParameters,
        scaledUncertainties: GaussianPeakParameterUncertainties,
        fixedParameters: Set<GaussianParameter>
    ) -> GaussianPeakParameterUncertainties {
        let rawParameters = rawParameters(scaledParameters)
        let baseline = fixedParameters.contains(.baseline) ? 0 : scaledUncertainties.baseline.map { $0 * yScale }
        let amplitude = fixedParameters.contains(.amplitude) ? 0 : scaledUncertainties.amplitude.map { $0 * yScale }
        let center = fixedParameters.contains(.center) ? 0 : scaledUncertainties.center.map { $0 * xScale }
        let sigma = fixedParameters.contains(.logSigma) ? 0 : scaledUncertainties.sigma.map { $0 * xScale }
        let peakY = combineErrors([baseline, amplitude])
        let area = combineErrors([
            amplitude.map { abs(rawParameters.sigma * sqrt(2 * Double.pi)) * $0 },
            sigma.map { abs(rawParameters.amplitude * sqrt(2 * Double.pi)) * $0 }
        ])
        let fwhm = sigma.map { 2 * sqrt(2 * log(2)) * $0 }

        return GaussianPeakParameterUncertainties(
            baseline: baseline,
            amplitude: amplitude,
            center: center,
            sigma: sigma,
            peakY: peakY,
            area: area,
            fwhm: fwhm
        )
    }

    func rawCovariance(_ covariance: [[Double]]) -> [[Double]] {
        let scales = [yScale, yScale, xScale, xScale]
        return covariance.enumerated().map { rowIndex, row in
            row.enumerated().map { columnIndex, value in
                value * scales[rowIndex] * scales[columnIndex]
            }
        }
    }

    func rawResidual(_ residual: FitResidual) -> FitResidual {
        FitResidual(
            xObserved: xOffset + residual.xObserved * xScale,
            yObserved: yOffset + residual.yObserved * yScale,
            xAdjusted: xOffset + residual.xAdjusted * xScale,
            yFitted: yOffset + residual.yFitted * yScale,
            xResidual: residual.xResidual * xScale,
            yResidual: residual.yResidual * yScale,
            weightedDistance: residual.weightedDistance
        )
    }
}

private extension FitParameterControl {
    func scaled(offset: Double, scale: Double) -> FitParameterControl {
        switch self {
        case .automatic:
            return .automatic
        case .seeded(let value):
            return .seeded((value - offset) / scale)
        case .fixed(let value):
            return .fixed((value - offset) / scale)
        case .bounded(let initial, let lower, let upper):
            return .bounded(
                initial: initial.map { ($0 - offset) / scale },
                lower: lower.map { ($0 - offset) / scale },
                upper: upper.map { ($0 - offset) / scale }
            )
        }
    }

    func scaled(scale: Double) -> FitParameterControl {
        switch self {
        case .automatic:
            return .automatic
        case .seeded(let value):
            return .seeded(value / scale)
        case .fixed(let value):
            return .fixed(value / scale)
        case .bounded(let initial, let lower, let upper):
            return .bounded(
                initial: initial.map { $0 / scale },
                lower: lower.map { $0 / scale },
                upper: upper.map { $0 / scale }
            )
        }
    }
}

private enum GaussianParameter: CaseIterable, Hashable {
    case baseline
    case amplitude
    case center
    case logSigma
}

private struct WorkingParameters: Hashable {
    var baseline: Double
    var amplitude: Double
    var center: Double
    var logSigma: Double

    var sigma: Double {
        exp(logSigma)
    }

    var rawValue: GaussianPeakParameters {
        GaussianPeakParameters(
            baseline: baseline,
            amplitude: amplitude,
            center: center,
            sigma: sigma
        )
    }

    var isFinite: Bool {
        baseline.isFinite && amplitude.isFinite && center.isFinite && logSigma.isFinite && sigma.isFinite && sigma > 0
    }

    func value(at x: Double) -> Double {
        baseline + amplitude * expTerm(at: x)
    }

    func derivatives(at x: Double) -> GaussianDerivatives {
        let sigma = sigma
        let delta = x - center
        let e = expTerm(at: x)
        let sigma2 = sigma * sigma
        let sigma3 = sigma2 * sigma

        return GaussianDerivatives(
            baseline: 1,
            amplitude: e,
            center: amplitude * e * delta / sigma2,
            logSigma: amplitude * e * delta * delta / sigma2,
            x: -amplitude * e * delta / sigma2,
            xx: amplitude * e * ((delta * delta / (sigma2 * sigma2)) - (1 / sigma2))
        )
    }

    private func expTerm(at x: Double) -> Double {
        let z = (x - center) / sigma
        return exp(-0.5 * z * z)
    }

    static func estimate(from observations: [ScaledObservation]) -> WorkingParameters {
        let sortedY = observations.map(\.y).sorted()
        let low = percentile(sortedY, fraction: 0.15)
        let high = percentile(sortedY, fraction: 0.85)
        let median = percentile(sortedY, fraction: 0.5)

        let usePositivePeak = abs(high - median) >= abs(low - median)
        let baseline = usePositivePeak ? low : high
        let target = usePositivePeak ? high : low
        let amplitude = target - baseline
        let peakObservation = observations.min { lhs, rhs in
            abs(lhs.y - target) < abs(rhs.y - target)
        }
        let center = peakObservation?.x ?? observations.map(\.x).averageOrZero
        let sigma = estimatedSigma(observations: observations, baseline: baseline, center: center)

        return WorkingParameters(
            baseline: baseline,
            amplitude: amplitude == 0 ? 1 : amplitude,
            center: center,
            logSigma: log(max(sigma, 1e-6))
        )
    }

    private static func percentile(_ values: [Double], fraction: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let index = min(max(Int(Double(values.count - 1) * fraction), 0), values.count - 1)
        return values[index]
    }

    private static func estimatedSigma(
        observations: [ScaledObservation],
        baseline: Double,
        center: Double
    ) -> Double {
        let weighted = observations.map { observation in
            (weight: abs(observation.y - baseline), delta: observation.x - center)
        }
        let weightSum = weighted.map(\.weight).reduce(0, +)
        if weightSum > 0 {
            let variance = weighted.reduce(0) { partial, item in
                partial + item.weight * item.delta * item.delta
            } / weightSum
            let sigma = sqrt(max(variance, 0))
            if sigma.isFinite, sigma > 0 { return sigma }
        }

        let xs = observations.map(\.x)
        let span = (xs.max() ?? 1) - (xs.min() ?? 0)
        return max(span / 6, 1e-3)
    }
}

private struct GaussianDerivatives {
    let baseline: Double
    let amplitude: Double
    let center: Double
    let logSigma: Double
    let x: Double
    let xx: Double

    func derivative(for parameter: GaussianParameter) -> Double {
        switch parameter {
        case .baseline:
            return baseline
        case .amplitude:
            return amplitude
        case .center:
            return center
        case .logSigma:
            return logSigma
        }
    }
}

private struct ParameterControls {
    let baseline: ParameterControl
    let amplitude: ParameterControl
    let center: ParameterControl
    let logSigma: ParameterControl

    init(specification: GaussianPeakSpecification, defaults: WorkingParameters) {
        baseline = ParameterControl(control: specification.baseline, defaultValue: defaults.baseline)
        amplitude = ParameterControl(control: specification.amplitude, defaultValue: defaults.amplitude)
        center = ParameterControl(control: specification.center, defaultValue: defaults.center)
        logSigma = ParameterControl(
            control: specification.sigma.logScaled,
            defaultValue: defaults.logSigma,
            lowerFallback: log(1e-6)
        )
    }

    var freeParameters: [GaussianParameter] {
        GaussianParameter.allCases.filter { !fixedParameters.contains($0) }
    }

    var freeParameterCount: Int {
        freeParameters.count
    }

    var fixedParameters: Set<GaussianParameter> {
        var result = Set<GaussianParameter>()
        if baseline.isFixed { result.insert(.baseline) }
        if amplitude.isFixed { result.insert(.amplitude) }
        if center.isFixed { result.insert(.center) }
        if logSigma.isFixed { result.insert(.logSigma) }
        return result
    }

    var initialParameters: WorkingParameters {
        WorkingParameters(
            baseline: baseline.initial,
            amplitude: amplitude.initial,
            center: center.initial,
            logSigma: logSigma.initial
        )
    }

    func applying(step: [Double], to parameters: WorkingParameters) -> WorkingParameters {
        var next = parameters
        for (index, parameter) in freeParameters.enumerated() {
            let value = value(for: parameter, in: next) + step[index]
            set(clamped(value, for: parameter), for: parameter, in: &next)
        }
        return next
    }

    func isSigmaAtBound(_ parameters: WorkingParameters) -> Bool {
        logSigma.isAtBound(parameters.logSigma)
    }

    func expandedCovariance(_ covariance: [[Double]]) -> [[Double]] {
        var expanded = Array(repeating: Array(repeating: 0.0, count: 4), count: 4)
        for (rowIndex, rowParameter) in freeParameters.enumerated() {
            for (columnIndex, columnParameter) in freeParameters.enumerated() {
                expanded[rowParameter.matrixIndex][columnParameter.matrixIndex] = covariance[rowIndex][columnIndex]
            }
        }
        return expanded
    }

    func sigmaTransformedCovariance(
        parameters: WorkingParameters,
        covariance: [[Double]]
    ) -> [[Double]] {
        var transformed = covariance
        let sigmaIndex = GaussianParameter.logSigma.matrixIndex
        for index in transformed.indices {
            transformed[sigmaIndex][index] *= parameters.sigma
            transformed[index][sigmaIndex] *= parameters.sigma
        }
        return transformed
    }

    func uncertainties(
        parameters: WorkingParameters,
        covariance: [[Double]]
    ) -> GaussianPeakParameterUncertainties {
        let baseline = standardError(for: .baseline, covariance: covariance)
        let amplitude = standardError(for: .amplitude, covariance: covariance)
        let center = standardError(for: .center, covariance: covariance)
        let sigma = standardError(for: .logSigma, covariance: covariance)
        let peakY = combineErrors([baseline, amplitude])
        let area = combineErrors([
            amplitude.map { abs(parameters.sigma * sqrt(2 * Double.pi)) * $0 },
            sigma.map { abs(parameters.amplitude * sqrt(2 * Double.pi)) * $0 }
        ])
        let fwhm = sigma.map { 2 * sqrt(2 * log(2)) * $0 }

        return GaussianPeakParameterUncertainties(
            baseline: baseline,
            amplitude: amplitude,
            center: center,
            sigma: sigma,
            peakY: peakY,
            area: area,
            fwhm: fwhm
        )
    }

    private func standardError(for parameter: GaussianParameter, covariance: [[Double]]) -> Double? {
        if fixedParameters.contains(parameter) { return 0 }
        let value = covariance[parameter.matrixIndex][parameter.matrixIndex]
        guard value.isFinite, value >= 0 else { return nil }
        return sqrt(value)
    }

    func value(for parameter: GaussianParameter, in parameters: WorkingParameters) -> Double {
        switch parameter {
        case .baseline: return parameters.baseline
        case .amplitude: return parameters.amplitude
        case .center: return parameters.center
        case .logSigma: return parameters.logSigma
        }
    }

    private func set(_ value: Double, for parameter: GaussianParameter, in parameters: inout WorkingParameters) {
        switch parameter {
        case .baseline: parameters.baseline = value
        case .amplitude: parameters.amplitude = value
        case .center: parameters.center = value
        case .logSigma: parameters.logSigma = value
        }
    }

    private func clamped(_ value: Double, for parameter: GaussianParameter) -> Double {
        switch parameter {
        case .baseline: return baseline.clamp(value)
        case .amplitude: return amplitude.clamp(value)
        case .center: return center.clamp(value)
        case .logSigma: return logSigma.clamp(value)
        }
    }
}

private struct ParameterControl {
    let initial: Double
    let lower: Double?
    let upper: Double?
    let isFixed: Bool

    init(
        control: FitParameterControl,
        defaultValue: Double,
        lowerFallback: Double? = nil
    ) {
        switch control {
        case .automatic:
            initial = defaultValue
            lower = lowerFallback
            upper = nil
            isFixed = false
        case .seeded(let value):
            initial = value
            lower = lowerFallback
            upper = nil
            isFixed = false
        case .fixed(let value):
            initial = value
            lower = value
            upper = value
            isFixed = true
        case .bounded(let seed, let lowerBound, let upperBound):
            lower = lowerBound ?? lowerFallback
            upper = upperBound
            initial = ParameterControl.clamp(seed ?? defaultValue, lower: lower, upper: upper)
            isFixed = false
        }
    }

    func clamp(_ value: Double) -> Double {
        Self.clamp(value, lower: lower, upper: upper)
    }

    func isAtBound(_ value: Double) -> Bool {
        let tolerance = 1e-6
        if let lower, abs(value - lower) < tolerance { return true }
        if let upper, abs(value - upper) < tolerance { return true }
        return false
    }

    private static func clamp(_ value: Double, lower: Double?, upper: Double?) -> Double {
        var result = value
        if let lower { result = max(result, lower) }
        if let upper { result = min(result, upper) }
        return result
    }
}

private extension FitParameterControl {
    var logScaled: FitParameterControl {
        switch self {
        case .automatic:
            return .automatic
        case .seeded(let value):
            return .seeded(log(max(value, 1e-12)))
        case .fixed(let value):
            return .fixed(log(max(value, 1e-12)))
        case .bounded(let initial, let lower, let upper):
            return .bounded(
                initial: initial.map { log(max($0, 1e-12)) },
                lower: lower.map { log(max($0, 1e-12)) },
                upper: upper.map { log(max($0, 1e-12)) }
            )
        }
    }
}

private extension GaussianParameter {
    var matrixIndex: Int {
        switch self {
        case .baseline: return 0
        case .amplitude: return 1
        case .center: return 2
        case .logSigma: return 3
        }
    }
}

private struct AdjustedPoint {
    let observation: ScaledObservation
    let xAdjusted: Double
    let yFitted: Double
    let xScale: Double
    let yScale: Double

    var xResidual: Double {
        xAdjusted - observation.x
    }

    var yResidual: Double {
        observation.y - yFitted
    }

    var weightedDistance: Double {
        let xTerm = observation.xStandardDeviation > 0
            ? xResidual / observation.xStandardDeviation
            : 0
        let yTerm = yResidual / yScale
        return sqrt(xTerm * xTerm + yTerm * yTerm)
    }

    var residual: FitResidual {
        FitResidual(
            xObserved: observation.x,
            yObserved: observation.y,
            xAdjusted: xAdjusted,
            yFitted: yFitted,
            xResidual: xResidual,
            yResidual: yResidual,
            weightedDistance: weightedDistance
        )
    }
}

private struct Evaluation {
    let adjustedPoints: [AdjustedPoint]
    let objective: Double
    let observations: [ScaledObservation]

    init(parameters: WorkingParameters, observations: [ScaledObservation]) {
        self.observations = observations
        adjustedPoints = observations.map { observation in
            let xAdjusted = Evaluation.adjustedX(for: observation, parameters: parameters)
            let yFitted = parameters.value(at: xAdjusted)
            return AdjustedPoint(
                observation: observation,
                xAdjusted: xAdjusted,
                yFitted: yFitted,
                xScale: observation.xStandardDeviation,
                yScale: observation.yStandardDeviation > 0 ? observation.yStandardDeviation : 1
            )
        }
        objective = adjustedPoints.reduce(0) { partial, point in
            let xTerm = point.observation.xStandardDeviation > 0
                ? point.xResidual / point.observation.xStandardDeviation
                : 0
            let yTerm = point.yResidual / point.yScale
            return partial + xTerm * xTerm + yTerm * yTerm
        }
    }

    var residuals: [FitResidual] {
        adjustedPoints.map(\.residual)
    }

    var weightedResidualVector: [Double] {
        adjustedPoints.flatMap { point in
            let xComponents = point.observation.xStandardDeviation > 0
                ? [point.xResidual / point.observation.xStandardDeviation]
                : []
            return xComponents + [point.yResidual / point.yScale]
        }
    }

    var residualComponentCount: Int {
        adjustedPoints.reduce(0) { count, point in
            count + 1 + (point.observation.xStandardDeviation > 0 ? 1 : 0)
        }
    }

    var hasHighOrthogonalAdjustment: Bool {
        adjustedPoints.contains { point in
            guard point.observation.xStandardDeviation > 0 else { return false }
            return abs(point.xResidual / point.observation.xStandardDeviation) > 3
        }
    }

    private static func adjustedX(
        for observation: ScaledObservation,
        parameters: WorkingParameters
    ) -> Double {
        guard observation.xStandardDeviation > 0 else { return observation.x }

        var x = observation.x
        let sx2 = observation.xStandardDeviation * observation.xStandardDeviation
        let sy = observation.yStandardDeviation > 0 ? observation.yStandardDeviation : 1
        let sy2 = sy * sy
        let maximumStep = max(3 * observation.xStandardDeviation, 1e-6)

        for _ in 0..<8 {
            let fitted = parameters.value(at: x)
            let derivatives = parameters.derivatives(at: x)
            let residual = observation.y - fitted
            let gradient = ((x - observation.x) / sx2) - (residual * derivatives.x / sy2)
            let curvature = (1 / sx2) + ((derivatives.x * derivatives.x - residual * derivatives.xx) / sy2)
            guard curvature.isFinite, abs(curvature) > 1e-12 else { break }

            let rawStep = gradient / curvature
            let step = min(max(rawStep, -maximumStep), maximumStep)
            guard step.isFinite else { break }
            x -= step
            if abs(step) < 1e-8 { break }
        }

        return x
    }
}

private enum SmallLinearAlgebra {
    static func solve(_ matrix: [[Double]], _ rhs: [Double]) -> [Double]? {
        let n = rhs.count
        guard matrix.count == n, matrix.allSatisfy({ $0.count == n }) else { return nil }
        var a = matrix
        var b = rhs

        for pivotIndex in 0..<n {
            guard let pivotRow = (pivotIndex..<n).max(by: {
                abs(a[$0][pivotIndex]) < abs(a[$1][pivotIndex])
            }) else { return nil }
            if abs(a[pivotRow][pivotIndex]) < 1e-14 { return nil }
            if pivotRow != pivotIndex {
                a.swapAt(pivotRow, pivotIndex)
                b.swapAt(pivotRow, pivotIndex)
            }

            for row in (pivotIndex + 1)..<n {
                let factor = a[row][pivotIndex] / a[pivotIndex][pivotIndex]
                guard factor.isFinite else { return nil }
                for column in pivotIndex..<n {
                    a[row][column] -= factor * a[pivotIndex][column]
                }
                b[row] -= factor * b[pivotIndex]
            }
        }

        var x = Array(repeating: 0.0, count: n)
        for row in stride(from: n - 1, through: 0, by: -1) {
            let sum = ((row + 1)..<n).reduce(0.0) { partial, column in
                partial + a[row][column] * x[column]
            }
            let denominator = a[row][row]
            guard abs(denominator) >= 1e-14 else { return nil }
            x[row] = (b[row] - sum) / denominator
            guard x[row].isFinite else { return nil }
        }
        return x
    }

    static func inverse(_ matrix: [[Double]]) -> [[Double]]? {
        let n = matrix.count
        guard n > 0, matrix.allSatisfy({ $0.count == n }) else { return nil }

        let columns = (0..<n).map { column -> [Double]? in
            var rhs = Array(repeating: 0.0, count: n)
            rhs[column] = 1.0
            return solve(matrix, rhs)
        }

        guard columns.allSatisfy({ $0 != nil }) else { return nil }
        let unwrapped = columns.compactMap { $0 }
        return (0..<n).map { row in
            (0..<n).map { column in
                unwrapped[column][row]
            }
        }
    }

    static func isIllConditioned(_ matrix: [[Double]]) -> Bool {
        let diagonal = matrix.indices.map { abs(matrix[$0][$0]) }.filter { $0.isFinite && $0 > 0 }
        guard let minValue = diagonal.min(), let maxValue = diagonal.max(), maxValue > 0 else { return true }
        return minValue / maxValue < 1e-10
    }
}

private func combineErrors(_ errors: [Double?]) -> Double? {
    let values = errors.compactMap { $0 }
    guard values.count == errors.count else { return nil }
    return sqrt(values.reduce(0) { $0 + $1 * $1 })
}

private extension Array where Element == Double {
    var averageOrZero: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension Array where Element: Hashable {
    var uniquePreservingOrder: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
