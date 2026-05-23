//
//  ShapiroWilkTests.swift
//  UncertainValueStatistics
//

import Foundation
import Testing
import UncertainValueStatistics
import UncertainValueSupport

private enum TestConstants {
    static let wTolerance: Double = 0.02
    /// Royston p-value approximation diverges from SciPy's exact algorithm,
    /// especially for small n. This tolerance covers the expected gap.
    static let pTolerance: Double = 0.06
}

struct ShapiroWilkTests {

    // MARK: - Normal Data (should not reject)

    @Test func normalDataTenElements() throws {
        let values = [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0.90)
        #expect(result.pValue > 0.05)
    }

    @Test func normalDataTwentyElements() throws {
        let values = [
            2.4, 3.1, 2.8, 3.5, 2.9, 3.2, 2.7, 3.0, 3.3, 2.6,
            3.1, 2.5, 3.4, 2.8, 3.0, 2.9, 3.2, 2.7, 3.1, 2.8
        ]
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0.90)
        #expect(result.pValue > 0.05)
    }

    @Test func normalDataThirtyElements() throws {
        let values = [
            50.1, 49.8, 50.3, 49.9, 50.0, 50.2, 49.7, 50.1, 49.9, 50.0,
            50.4, 49.6, 50.2, 49.8, 50.1, 50.3, 49.5, 50.0, 49.7, 50.2,
            50.1, 49.9, 50.0, 50.2, 49.8, 50.1, 49.6, 50.3, 49.9, 50.0
        ]
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0.90)
        #expect(result.pValue > 0.05)
    }

    @Test func symmetricDistributionFiveElements() throws {
        let values = [-2.0, -1.0, 0.0, 1.0, 2.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0.90)
    }

    @Test func typicalPhysicsLabData() throws {
        // Repeated measurements of a length (cm) — realistic use case
        let values = [15.23, 15.25, 15.21, 15.24, 15.22, 15.26, 15.23, 15.24]
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0.85)
        #expect(result.pValue > 0.05)
    }

    // MARK: - Non-Normal Data (should reject)

    @Test func heavilySkewedData() throws {
        let values = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 10.0, 20.0, 50.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w < 0.85)
        #expect(result.pValue < 0.05)
    }

    @Test func bimodalData() throws {
        let values = [1.0, 1.1, 1.2, 1.0, 1.1, 9.0, 9.1, 9.2, 9.0, 9.1]
        let result = try values.shapiroWilkTest()
        #expect(result.w < 0.85)
    }

    @Test func extremeOutlierData() throws {
        var values = [Double](repeating: 5.0, count: 9)
        values.append(1000.0)
        let result = try values.shapiroWilkTest()
        #expect(result.w < 0.70)
        #expect(result.pValue < 0.01)
    }

    @Test func discreteUniformData() throws {
        // Perfectly uniform: 1,2,3,...,10
        let values = (1...10).map { Double($0) }
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
    }

    @Test func exponentialLikeData() throws {
        let values = [0.1, 0.3, 0.5, 0.8, 1.2, 2.0, 3.5, 6.0, 10.0, 20.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w < 0.90)
    }

    @Test func uShapedData() throws {
        // U-shaped: many values at extremes, few in middle
        let values = [1.0, 1.0, 1.0, 1.0, 5.5, 10.0, 10.0, 10.0, 10.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w < 0.90)
    }

    // MARK: - W Statistic Range Invariants

    @Test func wAlwaysBetweenZeroAndOne() throws {
        let datasets: [[Double]] = [
            [1.0, 2.0, 3.0],
            [1.0, 1.0, 1.0, 2.0],
            [-100.0, 0.0, 100.0],
            [0.001, 0.002, 0.003, 0.004, 0.005],
            [1e6, 2e6, 3e6, 4e6, 5e6, 6e6, 7e6],
        ]
        for values in datasets {
            let result = try values.shapiroWilkTest()
            #expect(result.w > 0, "W should be > 0 for \(values)")
            #expect(result.w <= 1.0, "W should be <= 1 for \(values)")
        }
    }

    @Test func pValueAlwaysBetweenZeroAndOne() throws {
        let datasets: [[Double]] = [
            [1.0, 2.0, 3.0],
            [1.0, 1.0, 2.0, 10.0, 100.0],
            [10.1, 9.8, 10.3, 9.9, 10.0],
            [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0],
        ]
        for values in datasets {
            let result = try values.shapiroWilkTest()
            #expect(result.pValue >= 0, "p should be >= 0 for \(values)")
            #expect(result.pValue <= 1.0, "p should be <= 1 for \(values)")
        }
    }

    // MARK: - Edge Cases: Minimum Size

    @Test func threeElements() throws {
        let result = try [1.0, 2.0, 3.0].shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
        #expect(result.pValue >= 0)
        #expect(result.pValue <= 1.0)
    }

    @Test func threeElementsSkewed() throws {
        let result = try [1.0, 2.0, 100.0].shapiroWilkTest()
        #expect(result.w < 0.90)
    }

    @Test func fourElements() throws {
        let result = try [1.0, 2.0, 3.0, 4.0].shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
    }

    @Test func fiveElementsSymmetric() throws {
        let result = try [1.0, 3.0, 5.0, 7.0, 9.0].shapiroWilkTest()
        #expect(result.w > 0.90)
    }

    // MARK: - Edge Cases: Identical Values

    @Test func identicalValuesFive() throws {
        let result = try [5.0, 5.0, 5.0, 5.0, 5.0].shapiroWilkTest()
        #expect(result.w >= 0.99)
    }

    @Test func identicalValuesTen() throws {
        let result = try [Double](repeating: 42.0, count: 10).shapiroWilkTest()
        #expect(result.w >= 0.99)
    }

    @Test func nearlyIdenticalValues() throws {
        // Values differ by machine epsilon
        let base = 100.0
        let values = (0..<5).map { base + Double($0) * 1e-14 }
        let result = try values.shapiroWilkTest()
        #expect(result.w.isFinite)
    }

    // MARK: - Edge Cases: Insufficient Data

    @Test func insufficientTwoElements() {
        #expect(throws: UncertainValueError.self) {
            try [1.0, 2.0].shapiroWilkTest()
        }
    }

    @Test func insufficientOneElement() {
        #expect(throws: UncertainValueError.self) {
            try [42.0].shapiroWilkTest()
        }
    }

    @Test func insufficientEmptyArray() {
        #expect(throws: UncertainValueError.self) {
            try [Double]().shapiroWilkTest()
        }
    }

    // MARK: - Tabulated Weight Boundary (n=50 is last tabulated, n=51 is approximated)

    @Test func tabulatedBoundaryN50() throws {
        // n=50: uses tabulated weights
        let values = (1...50).map { Double($0) + Double.random(in: -0.5...0.5) }
        let result = try values.sorted().shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
        #expect(result.pValue >= 0)
        #expect(result.pValue <= 1.0)
    }

    @Test func approximatedWeightsN51() throws {
        // n=51: first size to use approximated weights
        let values = (1...51).map { Double($0) }
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
    }

    @Test func approximatedWeightsN100() throws {
        let values = (1...100).map { Double($0) }
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
    }

    // MARK: - Larger Samples

    @Test func largeSampleNormalLikeN60() throws {
        // Quasi-normal: linearly spaced around zero
        let values = (0..<60).map { Double($0 - 30) / 10.0 }
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0)
        #expect(result.w <= 1.0)
        #expect(result.pValue >= 0)
        #expect(result.pValue <= 1.0)
    }

    @Test func largeSampleSkewedN60() throws {
        // Exponential-like for n > 50
        let values = (1...60).map { pow(1.1, Double($0)) }
        let result = try values.shapiroWilkTest()
        #expect(result.w < 0.90)
    }

    // MARK: - Ordering Invariance

    @Test func resultIndependentOfInputOrder() throws {
        let sorted = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
        let reversed = sorted.reversed().map { $0 }
        let shuffled = [5.0, 2.0, 8.0, 1.0, 6.0, 3.0, 7.0, 4.0]

        let resultSorted = try sorted.shapiroWilkTest()
        let resultReversed = try reversed.shapiroWilkTest()
        let resultShuffled = try shuffled.shapiroWilkTest()

        #expect(abs(resultSorted.w - resultReversed.w) < TestConstants.wTolerance)
        #expect(abs(resultSorted.w - resultShuffled.w) < TestConstants.wTolerance)
    }

    // MARK: - Shift and Scale Invariance

    @Test func wInvariantUnderShift() throws {
        let values = [1.0, 3.0, 5.0, 7.0, 9.0, 2.0, 4.0, 6.0]
        let shifted = values.map { $0 + 10000.0 }
        let resultOriginal = try values.shapiroWilkTest()
        let resultShifted = try shifted.shapiroWilkTest()
        #expect(abs(resultOriginal.w - resultShifted.w) < TestConstants.wTolerance)
    }

    @Test func wInvariantUnderPositiveScale() throws {
        let values = [1.0, 3.0, 5.0, 7.0, 9.0, 2.0, 4.0, 6.0]
        let scaled = values.map { $0 * 1000.0 }
        let resultOriginal = try values.shapiroWilkTest()
        let resultScaled = try scaled.shapiroWilkTest()
        #expect(abs(resultOriginal.w - resultScaled.w) < TestConstants.wTolerance)
    }

    // MARK: - Numerical Stability

    @Test func largeValuesStable() throws {
        let values = [1e15, 1.1e15, 0.9e15, 1.05e15, 0.95e15]
        let result = try values.shapiroWilkTest()
        #expect(result.w.isFinite)
        #expect(result.pValue.isFinite)
    }

    @Test func smallValuesStable() throws {
        let values = [1e-15, 1.1e-15, 0.9e-15, 1.05e-15, 0.95e-15]
        let result = try values.shapiroWilkTest()
        #expect(result.w.isFinite)
        #expect(result.pValue.isFinite)
    }

    @Test func negativeValuesStable() throws {
        let values = [-10.0, -8.0, -6.0, -4.0, -2.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w > 0.90)
    }

    @Test func mixedSignValuesStable() throws {
        let values = [-3.0, -1.0, 0.0, 1.0, 3.0, -2.0, 2.0]
        let result = try values.shapiroWilkTest()
        #expect(result.w.isFinite)
        #expect(result.pValue.isFinite)
    }

    // MARK: - Discrimination Power

    @Test func moreNormalDataGivesHigherW() throws {
        // Symmetric (near-normal) vs heavily skewed
        let normalish = [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0]
        let skewed = [1.0, 1.0, 1.0, 2.0, 5.0, 10.0, 50.0]

        let wNormal = try normalish.shapiroWilkTest().w
        let wSkewed = try skewed.shapiroWilkTest().w

        #expect(wNormal > wSkewed)
    }

    @Test func highPValueForNormalLowForNonNormal() throws {
        let normal = [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0]
        let nonNormal = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 10.0, 20.0, 50.0]

        let pNormal = try normal.shapiroWilkTest().pValue
        let pNonNormal = try nonNormal.shapiroWilkTest().pValue

        #expect(pNormal > pNonNormal)
    }

    // MARK: - SciPy Reference Values (Small Sample, n <= 11)
    //
    // Ground truth generated by scipy.stats.shapiro (numpy 2.0.2).
    // W tolerance: 0.02 (weight table rounding).
    // p tolerance: 0.06 (Royston polynomial approximation vs SciPy's exact algorithm).

    @Test func scipyReferenceSkewedN11() throws {
        // SciPy: W = 0.7888, p = 0.0067
        let values = [148.0, 154.0, 158.0, 160.0, 161.0, 162.0, 166.0, 170.0, 182.0, 195.0, 236.0]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.7888) < TestConstants.wTolerance,
                "W: expected ≈ 0.789, got \(result.w)")
        #expect(result.pValue < 0.05,
                "p: expected < 0.05 (SciPy: 0.0067), got \(result.pValue)")
    }

    @Test func scipyReferenceNearNormalN8() throws {
        // SciPy: W = 0.8730, p = 0.1611
        let values = [38.7, 41.5, 43.8, 44.5, 45.5, 46.0, 47.7, 58.0]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.8730) < TestConstants.wTolerance,
                "W: expected ≈ 0.873, got \(result.w)")
        #expect(abs(result.pValue - 0.1611) < TestConstants.pTolerance,
                "p: expected ≈ 0.161 (SciPy: 0.1611), got \(result.pValue)")
    }

    @Test func scipyReferenceSymmetricN5() throws {
        // SciPy: W = 0.9868, p = 0.9672
        let values = [-2.0, -1.0, 0.0, 1.0, 2.0]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.9868) < TestConstants.wTolerance,
                "W: expected ≈ 0.987, got \(result.w)")
        #expect(result.pValue > 0.5,
                "p: expected high (SciPy: 0.9672), got \(result.pValue)")
    }

    @Test func scipyReferenceHeavilySkewedN10() throws {
        // SciPy: W = 0.6059, p = 0.0001
        let values = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 3.0, 10.0, 20.0, 50.0]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.6059) < TestConstants.wTolerance,
                "W: expected ≈ 0.606, got \(result.w)")
        #expect(result.pValue < 0.01,
                "p: expected < 0.01 (SciPy: 0.0001), got \(result.pValue)")
    }

    @Test func scipyReferenceNormalN10() throws {
        // SciPy: W = 0.9837, p = 0.9819
        let values = [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.9837) < TestConstants.wTolerance,
                "W: expected ≈ 0.984, got \(result.w)")
        #expect(result.pValue > 0.5,
                "p: expected high (SciPy: 0.9819), got \(result.pValue)")
    }

    // MARK: - SciPy Reference Values (Large Sample, n > 11)

    @Test func scipyReferenceNormalN12() throws {
        // SciPy: W = 0.9705, p = 0.9155
        let values = [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0, 10.1, 9.8]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.9705) < TestConstants.wTolerance,
                "W: expected ≈ 0.970, got \(result.w)")
        #expect(result.pValue > 0.5,
                "p: expected high (SciPy: 0.9155), got \(result.pValue)")
    }

    @Test func scipyReferenceUniformN12() throws {
        // SciPy: W = 0.9669, p = 0.8757
        let values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.9669) < TestConstants.wTolerance,
                "W: expected ≈ 0.967, got \(result.w)")
        #expect(result.pValue > 0.5,
                "p: expected high (SciPy: 0.8757), got \(result.pValue)")
    }

    @Test func scipyReferenceNormalN20() throws {
        // SciPy: W = 0.9691, p = 0.7364
        let values = [
            50.1, 49.8, 50.3, 49.9, 50.0, 50.2, 49.7, 50.1, 49.9, 50.0,
            50.4, 49.6, 50.2, 49.8, 50.1, 50.3, 49.5, 50.0, 49.7, 50.2,
        ]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.9691) < TestConstants.wTolerance,
                "W: expected ≈ 0.969, got \(result.w)")
        #expect(result.pValue > 0.3,
                "p: expected high (SciPy: 0.7364), got \(result.pValue)")
    }

    @Test func scipyReferenceSkewedN20() throws {
        // SciPy: W = 0.7456, p = 0.0001
        let values = [
            1.0, 1.1, 1.2, 1.3, 1.5, 1.8, 2.2, 2.8, 3.5, 4.5,
            5.8, 7.5, 9.8, 12.8, 16.7, 21.8, 28.4, 37.0, 48.2, 62.7,
        ]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.7456) < TestConstants.wTolerance,
                "W: expected ≈ 0.746, got \(result.w)")
        #expect(result.pValue < 0.01,
                "p: expected < 0.01 (SciPy: 0.0001), got \(result.pValue)")
    }

    @Test func scipyReferencePhysicsLabN15() throws {
        // SciPy: W = 0.9490, p = 0.5085
        let values = [
            9.81, 9.79, 9.83, 9.80, 9.82, 9.78, 9.81, 9.80,
            9.82, 9.79, 9.81, 9.83, 9.80, 9.79, 9.81,
        ]
        let result = try values.shapiroWilkTest()
        #expect(abs(result.w - 0.9490) < TestConstants.wTolerance,
                "W: expected ≈ 0.949, got \(result.w)")
        #expect(result.pValue > 0.1,
                "p: expected high (SciPy: 0.5085), got \(result.pValue)")
    }

    // MARK: - Regression: p-value Must Not Saturate to 1.0

    @Test func pValueNeverSaturatesToOneForRealData() throws {
        // The original bug: p-value was always 1.0 for n > 11
        // due to incorrect Royston normalizing variable.
        let datasets: [[Double]] = [
            [10.1, 9.8, 10.3, 9.9, 10.0, 10.2, 9.7, 10.1, 9.9, 10.0, 10.1, 9.8],
            [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0],
            [50.1, 49.8, 50.3, 49.9, 50.0, 50.2, 49.7, 50.1, 49.9, 50.0,
             50.4, 49.6, 50.2, 49.8, 50.1, 50.3, 49.5, 50.0, 49.7, 50.2],
        ]
        for values in datasets {
            let result = try values.shapiroWilkTest()
            #expect(result.pValue < 1.0,
                    "p must not saturate to 1.0 for n=\(values.count), got \(result.pValue)")
            #expect(result.pValue > 0.0,
                    "p must be positive for n=\(values.count), got \(result.pValue)")
        }
    }
}
