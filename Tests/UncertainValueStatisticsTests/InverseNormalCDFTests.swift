//
//  InverseNormalCDFTests.swift
//  UncertainValueStatistics
//

import Testing
import UncertainValueStatistics
import Foundation

private enum TestConstants {
    // Acklam's approximation has relative error < 1.15e-9
    static let tightAccuracy: Double = 1e-7
    static let standardAccuracy: Double = 1e-4
}

struct InverseNormalCDFTests {

    // MARK: - Exact Known Quantiles (from standard normal tables)

    @Test func inverseCDFMedian() {
        let z = NormalDistribution.inverseCDF(0.5)
        #expect(abs(z) < TestConstants.tightAccuracy)
    }

    @Test func inverseCDFAt975() {
        // z = 1.959963985...
        let z = NormalDistribution.inverseCDF(0.975)
        #expect(abs(z - 1.959964) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt025() {
        let z = NormalDistribution.inverseCDF(0.025)
        #expect(abs(z - (-1.959964)) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt90() {
        // z = 1.281551566...
        let z = NormalDistribution.inverseCDF(0.9)
        #expect(abs(z - 1.281552) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt10() {
        let z = NormalDistribution.inverseCDF(0.1)
        #expect(abs(z - (-1.281552)) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt95() {
        // z = 1.644853627...
        let z = NormalDistribution.inverseCDF(0.95)
        #expect(abs(z - 1.644854) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt05() {
        let z = NormalDistribution.inverseCDF(0.05)
        #expect(abs(z - (-1.644854)) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt99() {
        // z = 2.326347874...
        let z = NormalDistribution.inverseCDF(0.99)
        #expect(abs(z - 2.326348) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt01() {
        let z = NormalDistribution.inverseCDF(0.01)
        #expect(abs(z - (-2.326348)) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt999() {
        // z = 3.090232306...
        let z = NormalDistribution.inverseCDF(0.999)
        #expect(abs(z - 3.090232) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFAt001() {
        let z = NormalDistribution.inverseCDF(0.001)
        #expect(abs(z - (-3.090232)) < TestConstants.standardAccuracy)
    }

    // MARK: - Sigma Levels (round-trip verification)

    @Test func inverseCDFOneSigma() {
        let z = NormalDistribution.inverseCDF(0.8413447)
        #expect(abs(z - 1.0) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFTwoSigma() {
        let z = NormalDistribution.inverseCDF(0.9772499)
        #expect(abs(z - 2.0) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFThreeSigma() {
        let z = NormalDistribution.inverseCDF(0.9986501)
        #expect(abs(z - 3.0) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFNegativeOneSigma() {
        let z = NormalDistribution.inverseCDF(0.1586553)
        #expect(abs(z - (-1.0)) < TestConstants.standardAccuracy)
    }

    @Test func inverseCDFNegativeTwoSigma() {
        let z = NormalDistribution.inverseCDF(0.0227501)
        #expect(abs(z - (-2.0)) < TestConstants.standardAccuracy)
    }

    // MARK: - Symmetry Property

    @Test func inverseCDFSymmetryAt10And90() {
        let zLow = NormalDistribution.inverseCDF(0.1)
        let zHigh = NormalDistribution.inverseCDF(0.9)
        #expect(abs(zLow + zHigh) < TestConstants.tightAccuracy)
    }

    @Test func inverseCDFSymmetryAt20And80() {
        let zLow = NormalDistribution.inverseCDF(0.2)
        let zHigh = NormalDistribution.inverseCDF(0.8)
        #expect(abs(zLow + zHigh) < TestConstants.tightAccuracy)
    }

    @Test func inverseCDFSymmetryAt01And99() {
        let zLow = NormalDistribution.inverseCDF(0.01)
        let zHigh = NormalDistribution.inverseCDF(0.99)
        #expect(abs(zLow + zHigh) < TestConstants.tightAccuracy)
    }

    @Test func inverseCDFSymmetryAt001And999() {
        let zLow = NormalDistribution.inverseCDF(0.001)
        let zHigh = NormalDistribution.inverseCDF(0.999)
        #expect(abs(zLow + zHigh) < TestConstants.tightAccuracy)
    }

    // MARK: - Monotonicity

    @Test func inverseCDFStrictlyIncreasing() {
        let probabilities = stride(from: 0.01, through: 0.99, by: 0.01).map { $0 }
        let quantiles = probabilities.map { NormalDistribution.inverseCDF($0) }

        for i in 1..<quantiles.count {
            #expect(quantiles[i] > quantiles[i - 1], "Not monotonic at p=\(probabilities[i])")
        }
    }

    @Test func inverseCDFMonotonicInTails() {
        let tailProbabilities = [0.0001, 0.001, 0.005, 0.01, 0.025, 0.05]
        let quantiles = tailProbabilities.map { NormalDistribution.inverseCDF($0) }

        for i in 1..<quantiles.count {
            #expect(quantiles[i] > quantiles[i - 1])
        }
    }

    // MARK: - Boundary Conditions

    @Test func inverseCDFBoundaryZero() {
        let z = NormalDistribution.inverseCDF(0)
        #expect(z == -.infinity)
    }

    @Test func inverseCDFBoundaryOne() {
        let z = NormalDistribution.inverseCDF(1)
        #expect(z == .infinity)
    }

    @Test func inverseCDFNegativeInput() {
        let z = NormalDistribution.inverseCDF(-0.5)
        #expect(z == -.infinity)
    }

    @Test func inverseCDFInputGreaterThanOne() {
        let z = NormalDistribution.inverseCDF(1.5)
        #expect(z == .infinity)
    }

    // MARK: - Extreme Tails (finiteness and direction)

    @Test func inverseCDFVerySmallProbability() {
        let z = NormalDistribution.inverseCDF(1e-10)
        #expect(z.isFinite)
        #expect(z < -6.0)
    }

    @Test func inverseCDFVeryLargeProbability() {
        let z = NormalDistribution.inverseCDF(1 - 1e-10)
        #expect(z.isFinite)
        #expect(z > 6.0)
    }

    @Test func inverseCDFSmallestReasonable() {
        let z = NormalDistribution.inverseCDF(1e-15)
        #expect(z.isFinite)
        #expect(z < -7.0)
    }

    // MARK: - Region Boundaries (tests the transition between central and tail approximations)

    @Test func inverseCDFAtLowBoundary() {
        // pLow = 0.02425 — test just above and below
        let zBelow = NormalDistribution.inverseCDF(0.024)
        let zAt = NormalDistribution.inverseCDF(0.02425)
        let zAbove = NormalDistribution.inverseCDF(0.025)
        #expect(zBelow < zAt)
        #expect(zAt < zAbove)
    }

    @Test func inverseCDFAtHighBoundary() {
        let zBelow = NormalDistribution.inverseCDF(0.975)
        let zAt = NormalDistribution.inverseCDF(0.97575)
        let zAbove = NormalDistribution.inverseCDF(0.976)
        #expect(zBelow < zAt)
        #expect(zAt < zAbove)
    }

    @Test func inverseCDFContinuousAcrossLowBoundary() {
        // Values just inside and outside the low boundary should be close
        let zJustBelow = NormalDistribution.inverseCDF(0.02424)
        let zJustAbove = NormalDistribution.inverseCDF(0.02426)
        #expect(abs(zJustBelow - zJustAbove) < 0.01)
    }

    // MARK: - Q-Q Plot Use Case (order statistics positions)

    @Test func inverseCDFBlomCorrection() {
        // Blom's formula: p_i = (i - 3/8) / (n + 1/4)
        // For n=5, i=1..5: p = [0.119, 0.310, 0.500, 0.690, 0.881]
        let n = 5
        let quantiles = (1...n).map { i in
            NormalDistribution.inverseCDF((Double(i) - 0.375) / (Double(n) + 0.25))
        }

        #expect(quantiles[0] < 0)
        #expect(abs(quantiles[2]) < 0.01) // middle should be near 0
        #expect(quantiles[4] > 0)
        // Should be antisymmetric
        #expect(abs(quantiles[0] + quantiles[4]) < TestConstants.standardAccuracy)
        #expect(abs(quantiles[1] + quantiles[3]) < TestConstants.standardAccuracy)
    }
}
