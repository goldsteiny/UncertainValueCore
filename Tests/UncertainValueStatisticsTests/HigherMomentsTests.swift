//
//  HigherMomentsTests.swift
//  UncertainValueStatistics
//

import Testing
import UncertainValueStatistics
import UncertainValueSupport

private enum TestConstants {
    static let accuracy: Double = 1e-6
    static let looseAccuracy: Double = 1e-3
}

struct HigherMomentsTests {

    // MARK: - Skewness: Symmetric Distributions (should be zero)

    @Test func skewnessSymmetricFiveElements() throws {
        let values = [-2.0, -1.0, 0.0, 1.0, 2.0]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.accuracy)
    }

    @Test func skewnessSymmetricEvenCount() throws {
        let values = [-3.0, -1.0, 1.0, 3.0]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.accuracy)
    }

    @Test func skewnessSymmetricThreeElements() throws {
        let values = [1.0, 2.0, 3.0]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.accuracy)
    }

    @Test func skewnessSymmetricLarger() throws {
        let values = [-5.0, -3.0, -1.0, 0.0, 1.0, 3.0, 5.0]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.accuracy)
    }

    @Test func skewnessIdenticalValues() throws {
        let values = [5.0, 5.0, 5.0, 5.0]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.accuracy)
    }

    // MARK: - Skewness: Directional Tests

    @Test func skewnessRightSkewed() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 10.0]
        let skewness = try values.skewnessL2()
        #expect(skewness > 0)
    }

    @Test func skewnessLeftSkewed() throws {
        let values = [1.0, 7.0, 8.0, 9.0, 10.0]
        let skewness = try values.skewnessL2()
        #expect(skewness < 0)
    }

    @Test func skewnessStrongRightSkew() throws {
        // Exponential-like: strong right skew, skewness should be > 1
        let values = [0.1, 0.2, 0.3, 0.5, 0.8, 1.5, 3.0, 7.0, 15.0, 30.0]
        let skewness = try values.skewnessL2()
        #expect(skewness > 1.0)
    }

    @Test func skewnessStrongLeftSkew() throws {
        // Mirror of right-skewed data
        let values = [0.1, 0.2, 0.3, 0.5, 0.8, 1.5, 3.0, 7.0, 15.0, 30.0]
        let mirrored = values.map { 31.0 - $0 }
        let skewness = try mirrored.skewnessL2()
        #expect(skewness < -1.0)
    }

    @Test func skewnessAntisymmetry() throws {
        // Negating all values should negate skewness
        let values = [1.0, 2.0, 3.0, 4.0, 10.0]
        let negated = values.map { -$0 }
        let skewnessOriginal = try values.skewnessL2()
        let skewnessNegated = try negated.skewnessL2()
        #expect(abs(skewnessOriginal + skewnessNegated) < TestConstants.accuracy)
    }

    @Test func skewnessShiftInvariant() throws {
        // Adding a constant shouldn't change skewness
        let values = [1.0, 2.0, 3.0, 4.0, 10.0]
        let shifted = values.map { $0 + 1000.0 }
        let skewnessOriginal = try values.skewnessL2()
        let skewnessShifted = try shifted.skewnessL2()
        #expect(abs(skewnessOriginal - skewnessShifted) < TestConstants.looseAccuracy)
    }

    @Test func skewnessScaleInvariant() throws {
        // Multiplying by a positive constant shouldn't change skewness
        let values = [1.0, 2.0, 3.0, 4.0, 10.0]
        let scaled = values.map { $0 * 100.0 }
        let skewnessOriginal = try values.skewnessL2()
        let skewnessScaled = try scaled.skewnessL2()
        #expect(abs(skewnessOriginal - skewnessScaled) < TestConstants.looseAccuracy)
    }

    // MARK: - Skewness: Numerical Reference Values

    @Test func skewnessKnownValueRightTail() throws {
        // R: e1071::skewness(c(1,1,1,1,1,1,1,1,1,10), type=2) ≈ 3.0
        // Heavily concentrated at 1 with one outlier at 10
        let values = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 10.0]
        let skewness = try values.skewnessL2()
        #expect(skewness > 2.5)
        #expect(skewness < 3.5)
    }

    // MARK: - Skewness: Error Cases

    @Test func skewnessInsufficientTwoElements() {
        let values = [1.0, 2.0]
        #expect(throws: UncertainValueError.self) {
            try values.skewnessL2()
        }
    }

    @Test func skewnessInsufficientOneElement() {
        let values = [42.0]
        #expect(throws: UncertainValueError.self) {
            try values.skewnessL2()
        }
    }

    @Test func skewnessEmptyArray() {
        let values: [Double] = []
        #expect(throws: UncertainValueError.self) {
            try values.skewnessL2()
        }
    }

    // MARK: - Skewness: Numerical Stability

    @Test func skewnessLargeValues() throws {
        let values = [1e15, 2e15, 3e15, 4e15, 5e15]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.looseAccuracy)
    }

    @Test func skewnessSmallValues() throws {
        let values = [1e-15, 2e-15, 3e-15, 4e-15, 5e-15]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.looseAccuracy)
    }

    @Test func skewnessNegativeValues() throws {
        let values = [-10.0, -8.0, -6.0, -4.0, -2.0]
        let skewness = try values.skewnessL2()
        #expect(abs(skewness) < TestConstants.accuracy)
    }

    @Test func skewnessMixedSignValues() throws {
        // Right-skewed: most values negative, one large positive
        let values = [-5.0, -4.0, -3.0, -2.0, -1.0, 20.0]
        let skewness = try values.skewnessL2()
        #expect(skewness > 0)
    }

    // MARK: - Excess Kurtosis: Known Behavior

    @Test func kurtosisUniformLikeNegative() throws {
        // Evenly spaced data (uniform-like) has negative excess kurtosis
        let values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis < 0)
    }

    @Test func kurtosisHeavyTailedPositive() throws {
        // Values concentrated at center with extreme outliers
        let values = [0.0, 0.0, 0.0, 0.0, 0.0, 10.0, -10.0, 0.0, 0.0, 0.0]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis > 0)
    }

    @Test func kurtosisPeakedDistribution() throws {
        // Concentrated around mean
        let values = [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis > 0)
    }

    @Test func kurtosisIdenticalValuesZero() throws {
        let values = [3.0, 3.0, 3.0, 3.0, 3.0]
        let kurtosis = try values.excessKurtosisL2()
        #expect(abs(kurtosis) < TestConstants.accuracy)
    }

    @Test func kurtosisSymmetricBimodal() throws {
        // Bimodal symmetric: platykurtic (negative kurtosis)
        let values = [1.0, 1.0, 1.0, 1.0, 10.0, 10.0, 10.0, 10.0]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis < 0)
    }

    @Test func kurtosisShiftInvariant() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 100.0]
        let shifted = values.map { $0 + 5000.0 }
        let kurtosisOriginal = try values.excessKurtosisL2()
        let kurtosisShifted = try shifted.excessKurtosisL2()
        #expect(abs(kurtosisOriginal - kurtosisShifted) < TestConstants.looseAccuracy)
    }

    @Test func kurtosisScaleInvariant() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 100.0]
        let scaled = values.map { $0 * 50.0 }
        let kurtosisOriginal = try values.excessKurtosisL2()
        let kurtosisScaled = try scaled.excessKurtosisL2()
        #expect(abs(kurtosisOriginal - kurtosisScaled) < TestConstants.looseAccuracy)
    }

    @Test func kurtosisNegatedSameValue() throws {
        // Negating all values shouldn't change kurtosis (even moment)
        let values = [1.0, 2.0, 3.0, 4.0, 10.0]
        let negated = values.map { -$0 }
        let kurtosisOriginal = try values.excessKurtosisL2()
        let kurtosisNegated = try negated.excessKurtosisL2()
        #expect(abs(kurtosisOriginal - kurtosisNegated) < TestConstants.accuracy)
    }

    // MARK: - Excess Kurtosis: Numerical Reference

    @Test func kurtosisUniformSequenceReference() throws {
        // For {1,...,n}, excess kurtosis → -6/5 = -1.2 as n → ∞
        // For n=20: bias-corrected value is close to -1.2
        let values = (1...20).map { Double($0) }
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis < -1.0)
        #expect(kurtosis > -1.5)
    }

    @Test func kurtosisExtremeOutlier() throws {
        // Single extreme outlier should produce very high kurtosis
        var values = [Double](repeating: 0.0, count: 19)
        values.append(100.0)
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis > 10.0)
    }

    // MARK: - Excess Kurtosis: Error Cases

    @Test func kurtosisInsufficientThreeElements() {
        let values = [1.0, 2.0, 3.0]
        #expect(throws: UncertainValueError.self) {
            try values.excessKurtosisL2()
        }
    }

    @Test func kurtosisInsufficientTwoElements() {
        let values = [1.0, 2.0]
        #expect(throws: UncertainValueError.self) {
            try values.excessKurtosisL2()
        }
    }

    @Test func kurtosisInsufficientOneElement() {
        let values = [42.0]
        #expect(throws: UncertainValueError.self) {
            try values.excessKurtosisL2()
        }
    }

    @Test func kurtosisEmptyArray() {
        let values: [Double] = []
        #expect(throws: UncertainValueError.self) {
            try values.excessKurtosisL2()
        }
    }

    @Test func kurtosisFourElementsMinimum() throws {
        let values = [1.0, 2.0, 3.0, 4.0]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis.isFinite)
    }

    // MARK: - Excess Kurtosis: Numerical Stability

    @Test func kurtosisLargeValues() throws {
        let values = [1e12, 2e12, 3e12, 4e12, 5e12, 6e12, 7e12, 8e12]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis.isFinite)
        #expect(kurtosis < 0)
    }

    @Test func kurtosisSmallValues() throws {
        let values = [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12]
        let kurtosis = try values.excessKurtosisL2()
        #expect(kurtosis.isFinite)
        #expect(kurtosis < 0)
    }
}
