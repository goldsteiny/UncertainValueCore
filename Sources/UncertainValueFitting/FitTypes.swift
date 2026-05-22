//
//  FitTypes.swift
//  UncertainValueFitting
//
//  Public fitting models shared by apps and future analysis tools.
//

import Foundation

public struct FitObservation: Codable, Hashable, Sendable {
    public let x: Double
    public let y: Double
    public let xStandardDeviation: Double
    public let yStandardDeviation: Double

    public init(
        x: Double,
        y: Double,
        xStandardDeviation: Double = 0,
        yStandardDeviation: Double = 0
    ) {
        self.x = x
        self.y = y
        self.xStandardDeviation = abs(xStandardDeviation)
        self.yStandardDeviation = abs(yStandardDeviation)
    }

    public var isFinite: Bool {
        x.isFinite && y.isFinite && xStandardDeviation.isFinite && yStandardDeviation.isFinite
    }
}

public struct FitObservationSeries: Codable, Hashable, Sendable {
    public let observations: [FitObservation]

    public init(observations: [FitObservation]) {
        self.observations = observations
    }

    public func filtered(to xRange: ClosedRange<Double>?) -> FitObservationSeries {
        guard let xRange else { return self }
        return FitObservationSeries(
            observations: observations.filter { xRange.contains($0.x) }
        )
    }
}

public enum FitParameterControl: Codable, Hashable, Sendable {
    case automatic
    case seeded(Double)
    case fixed(Double)
    case bounded(initial: Double?, lower: Double?, upper: Double?)

    public var fixedValue: Double? {
        if case .fixed(let value) = self { return value }
        return nil
    }

    public var isFixed: Bool {
        fixedValue != nil
    }
}

public struct GaussianPeakSpecification: Codable, Hashable, Sendable {
    public var baseline: FitParameterControl
    public var amplitude: FitParameterControl
    public var center: FitParameterControl
    public var sigma: FitParameterControl

    public init(
        baseline: FitParameterControl = .automatic,
        amplitude: FitParameterControl = .automatic,
        center: FitParameterControl = .automatic,
        sigma: FitParameterControl = .automatic
    ) {
        self.baseline = baseline
        self.amplitude = amplitude
        self.center = center
        self.sigma = sigma
    }

    public static let automatic = GaussianPeakSpecification()
}

public struct GaussianPeakParameters: Codable, Hashable, Sendable {
    public let baseline: Double
    public let amplitude: Double
    public let center: Double
    public let sigma: Double

    public init(baseline: Double, amplitude: Double, center: Double, sigma: Double) {
        self.baseline = baseline
        self.amplitude = amplitude
        self.center = center
        self.sigma = sigma
    }

    public var peakY: Double {
        baseline + amplitude
    }

    public var area: Double {
        amplitude * sigma * sqrt(2 * Double.pi)
    }

    public var fwhm: Double {
        2 * sqrt(2 * log(2)) * sigma
    }
}

public struct GaussianPeakParameterUncertainties: Codable, Hashable, Sendable {
    public let baseline: Double?
    public let amplitude: Double?
    public let center: Double?
    public let sigma: Double?
    public let peakY: Double?
    public let area: Double?
    public let fwhm: Double?

    public init(
        baseline: Double?,
        amplitude: Double?,
        center: Double?,
        sigma: Double?,
        peakY: Double?,
        area: Double?,
        fwhm: Double?
    ) {
        self.baseline = baseline
        self.amplitude = amplitude
        self.center = center
        self.sigma = sigma
        self.peakY = peakY
        self.area = area
        self.fwhm = fwhm
    }

    public static let unavailable = GaussianPeakParameterUncertainties(
        baseline: nil,
        amplitude: nil,
        center: nil,
        sigma: nil,
        peakY: nil,
        area: nil,
        fwhm: nil
    )
}

public enum FitConvergenceStatus: String, Codable, Hashable, Sendable {
    case converged
    case maxIterations
    case insufficientData
    case singularSystem
    case invalidInput
}

public enum FitQualityWarning: Codable, Hashable, Sendable {
    case droppedNonFinitePoints(Int)
    case insufficientDegreesOfFreedom
    case weaklyConstrainedFit
    case illConditionedCovariance
    case covarianceUnavailable
    case sigmaAtBound
    case highOrthogonalAdjustment
    case weakLocalOptimum
    case ambiguousFitCandidates
}

public struct FitResidual: Codable, Hashable, Sendable {
    public let xObserved: Double
    public let yObserved: Double
    public let xAdjusted: Double
    public let yFitted: Double
    public let xResidual: Double
    public let yResidual: Double
    public let weightedDistance: Double

    public init(
        xObserved: Double,
        yObserved: Double,
        xAdjusted: Double,
        yFitted: Double,
        xResidual: Double,
        yResidual: Double,
        weightedDistance: Double
    ) {
        self.xObserved = xObserved
        self.yObserved = yObserved
        self.xAdjusted = xAdjusted
        self.yFitted = yFitted
        self.xResidual = xResidual
        self.yResidual = yResidual
        self.weightedDistance = weightedDistance
    }
}

public struct GaussianPeakFitResult: Codable, Hashable, Sendable {
    public let parameters: GaussianPeakParameters
    public let uncertainties: GaussianPeakParameterUncertainties
    public let covariance: [[Double]]?
    public let residuals: [FitResidual]
    public let observationsUsed: Int
    public let observationsDropped: Int
    public let degreesOfFreedom: Int
    public let reducedChiSquare: Double?
    public let iterations: Int
    public let status: FitConvergenceStatus
    public let warnings: [FitQualityWarning]

    public init(
        parameters: GaussianPeakParameters,
        uncertainties: GaussianPeakParameterUncertainties,
        covariance: [[Double]]?,
        residuals: [FitResidual],
        observationsUsed: Int,
        observationsDropped: Int,
        degreesOfFreedom: Int,
        reducedChiSquare: Double?,
        iterations: Int,
        status: FitConvergenceStatus,
        warnings: [FitQualityWarning]
    ) {
        self.parameters = parameters
        self.uncertainties = uncertainties
        self.covariance = covariance
        self.residuals = residuals
        self.observationsUsed = observationsUsed
        self.observationsDropped = observationsDropped
        self.degreesOfFreedom = degreesOfFreedom
        self.reducedChiSquare = reducedChiSquare
        self.iterations = iterations
        self.status = status
        self.warnings = warnings
    }
}
