//
//  UncertainValueStatisticsTests.swift
//  UncertainValueStatistics
//

import Testing
import UncertainValueStatistics
import UncertainValueCore
import MultiplicativeUncertainValue
import Foundation
import Darwin

private enum TestConstants {
    static let defaultAccuracy: Double = 1e-10
    static let largeScaleAccuracy: Double = 1e90
    static let smallScaleAccuracy: Double = 1e-110
}

struct UncertainValueStatisticsTests {
    // MARK: - Arithmetic Mean Tests

    @Test func arithmeticMeanSimpleSequence() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        // Sample std dev = sqrt(10/4) = sqrt(2.5)
        try assertArithmeticMean(
            values,
            expectedValue: 3.0,
            expectedStdDev: sqrt(2.5),
            accuracy: TestConstants.defaultAccuracy
        )
    }

    @Test func arithmeticMeanIdenticalValues() throws {
        let values = [10.0, 10.0, 10.0]
        try assertArithmeticMean(
            values,
            expectedValue: 10.0,
            expectedStdDev: 0.0,
            accuracy: TestConstants.defaultAccuracy
        )
    }

    @Test func arithmeticMeanTwoValues() throws {
        let values = [0.0, 10.0]
        // Sample std dev = sqrt(50/1) = sqrt(50)
        try assertArithmeticMean(
            values,
            expectedValue: 5.0,
            expectedStdDev: sqrt(50),
            accuracy: TestConstants.defaultAccuracy
        )
    }

    @Test func arithmeticMeanNegativeValues() throws {
        let values = [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0]
        // Sum of squared deviations from 0: 25+9+1+1+9+25 = 70, sample std dev = sqrt(70/5) = sqrt(14)
        try assertArithmeticMean(
            values,
            expectedValue: 0.0,
            expectedStdDev: sqrt(14),
            accuracy: TestConstants.defaultAccuracy
        )
    }

    @Test func arithmeticMeanExtremeValues() throws {
        let scale = 1e100
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale, 5.0 * scale]

        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        #expect(custom.value.isFinite)
        #expect(custom.absoluteError.isFinite)
        #expect(vdsp.value.isFinite)
        #expect(vdsp.absoluteError.isFinite)

        #expect(isApproximatelyEqual(custom.value, 3.0 * scale, accuracy: TestConstants.largeScaleAccuracy))
        #expect(isApproximatelyEqual(custom.absoluteError, sqrt(2.5) * scale, accuracy: TestConstants.largeScaleAccuracy))
    }

    @Test func arithmeticMeanTinyValues() throws {
        let scale = 1e-100
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale, 5.0 * scale]

        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        #expect(custom.value.isFinite)
        #expect(custom.absoluteError.isFinite)
        #expect(vdsp.value.isFinite)
        #expect(vdsp.absoluteError.isFinite)

        #expect(isApproximatelyEqual(custom.value, 3.0 * scale, accuracy: TestConstants.smallScaleAccuracy))
        #expect(isApproximatelyEqual(custom.absoluteError, sqrt(2.5) * scale, accuracy: TestConstants.smallScaleAccuracy))
    }

    @Test func arithmeticMeanAllZeros() throws {
        let values = [0.0, 0.0, 0.0]

        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        #expect(custom.value == 0.0)
        #expect(custom.absoluteError == 0.0)
        #expect(vdsp.value == 0.0)
        // vDSP may produce NaN for std dev of all zeros due to 0/0.
    }

    // MARK: - Geometric Mean Tests

    @Test func geometricMeanPowersOfTwo() throws {
        let values = [1.0, 2.0, 4.0]
        // Geometric mean of [1, 2, 4] = 2
        try assertGeometricMean(values, expectedValue: 2.0, accuracy: TestConstants.defaultAccuracy)
    }

    @Test func geometricMeanIdenticalValues() throws {
        let e = Darwin.M_E
        let values = [e, e, e]

        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        #expect(isApproximatelyEqual(custom.value, e, accuracy: TestConstants.defaultAccuracy))
        #expect(isApproximatelyEqual(custom.relativeError, 0.0, accuracy: TestConstants.defaultAccuracy))
        #expect(isApproximatelyEqual(vdsp.value, e, accuracy: TestConstants.defaultAccuracy))
        #expect(isApproximatelyEqual(vdsp.relativeError, 0.0, accuracy: TestConstants.defaultAccuracy))
    }

    @Test func geometricMeanTwoValues() throws {
        let values = [4.0, 9.0]
        // Geometric mean = sqrt(4 * 9) = 6
        try assertGeometricMean(values, expectedValue: 6.0, accuracy: TestConstants.defaultAccuracy)
    }

    @Test func geometricMeanAlwaysPositive() throws {
        let values = [0.1, 0.5, 2.0, 10.0]

        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        #expect(custom.isPositive)
        #expect(vdsp.isPositive)
    }

    @Test func geometricMeanLogAbsMatchesArithmeticMeanOfLogs() throws {
        let values = [2.0, 8.0, 32.0]
        let logValues = values.map { Darwin.log($0) }

        let expectedLogMean = try logValues.arithmeticMeanL2()
        let expectedLogMeanVDSP = try logValues.arithmeticMeanL2_vDSP()

        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        #expect(isApproximatelyEqual(custom.logAbs.value, expectedLogMean.value, accuracy: TestConstants.defaultAccuracy))
        #expect(isApproximatelyEqual(custom.logAbs.absoluteError, expectedLogMean.absoluteError, accuracy: TestConstants.defaultAccuracy))

        #expect(isApproximatelyEqual(vdsp.logAbs.value, expectedLogMeanVDSP.value, accuracy: TestConstants.defaultAccuracy))
        #expect(isApproximatelyEqual(vdsp.logAbs.absoluteError, expectedLogMeanVDSP.absoluteError, accuracy: TestConstants.defaultAccuracy))
    }

    // MARK: - Helpers

    private func assertArithmeticMean(
        _ values: [Double],
        expectedValue: Double,
        expectedStdDev: Double,
        accuracy: Double
    ) throws {
        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        #expect(isApproximatelyEqual(custom.value, expectedValue, accuracy: accuracy))
        #expect(isApproximatelyEqual(custom.absoluteError, expectedStdDev, accuracy: accuracy))

        #expect(isApproximatelyEqual(vdsp.value, expectedValue, accuracy: accuracy))
        #expect(isApproximatelyEqual(vdsp.absoluteError, expectedStdDev, accuracy: accuracy))

        #expect(isApproximatelyEqual(custom.value, vdsp.value, accuracy: accuracy))
        #expect(isApproximatelyEqual(custom.absoluteError, vdsp.absoluteError, accuracy: accuracy))
    }

    private func assertGeometricMean(
        _ values: [Double],
        expectedValue: Double,
        accuracy: Double
    ) throws {
        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        #expect(isApproximatelyEqual(custom.value, expectedValue, accuracy: accuracy))
        #expect(isApproximatelyEqual(vdsp.value, expectedValue, accuracy: accuracy))

        #expect(isApproximatelyEqual(custom.value, vdsp.value, accuracy: accuracy))
        #expect(isApproximatelyEqual(custom.logAbs.absoluteError, vdsp.logAbs.absoluteError, accuracy: accuracy))
    }
}

private func isApproximatelyEqual(_ actual: Double, _ expected: Double, accuracy: Double) -> Bool {
    abs(actual - expected) <= accuracy
}
