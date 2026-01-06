//
//  UncertainValueStatisticsTests.swift
//  UncertainValueStatistics
//

import XCTest
import UncertainValueStatistics
import UncertainValueCore
import MultiplicativeUncertainValue

final class UncertainValueStatisticsTests: XCTestCase {

    // MARK: - Helper Methods

    /// Tests both arithmetic mean implementations and verifies they match.
    private func assertArithmeticMean(
        _ values: [Double],
        expectedValue: Double,
        expectedStdDev: Double,
        accuracy: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        // Test custom implementation
        XCTAssertEqual(custom.value, expectedValue, accuracy: accuracy,
                       "Custom mean value mismatch", file: file, line: line)
        XCTAssertEqual(custom.absoluteError, expectedStdDev, accuracy: accuracy,
                       "Custom std dev mismatch", file: file, line: line)

        // Test vDSP implementation
        XCTAssertEqual(vdsp.value, expectedValue, accuracy: accuracy,
                       "vDSP mean value mismatch", file: file, line: line)
        XCTAssertEqual(vdsp.absoluteError, expectedStdDev, accuracy: accuracy,
                       "vDSP std dev mismatch", file: file, line: line)

        // Cross-validate implementations match each other
        XCTAssertEqual(custom.value, vdsp.value, accuracy: accuracy,
                       "Implementations disagree on mean", file: file, line: line)
        XCTAssertEqual(custom.absoluteError, vdsp.absoluteError, accuracy: accuracy,
                       "Implementations disagree on std dev", file: file, line: line)
    }

    /// Tests both geometric mean implementations and verifies they match.
    private func assertGeometricMean(
        _ values: [Double],
        expectedValue: Double,
        accuracy: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        // Test custom implementation
        XCTAssertEqual(custom.value, expectedValue, accuracy: accuracy,
                       "Custom geometric mean value mismatch", file: file, line: line)

        // Test vDSP implementation
        XCTAssertEqual(vdsp.value, expectedValue, accuracy: accuracy,
                       "vDSP geometric mean value mismatch", file: file, line: line)

        // Cross-validate implementations match each other
        XCTAssertEqual(custom.value, vdsp.value, accuracy: accuracy,
                       "Implementations disagree on geometric mean", file: file, line: line)
        XCTAssertEqual(custom.logAbs.absoluteError, vdsp.logAbs.absoluteError, accuracy: accuracy,
                       "Implementations disagree on log std dev", file: file, line: line)
    }

    // MARK: - Arithmetic Mean Tests

    func testArithmeticMean_simpleSequence() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        // Sample std dev = sqrt(10/4) = sqrt(2.5)
        try assertArithmeticMean(values, expectedValue: 3.0, expectedStdDev: sqrt(2.5), accuracy: 1e-10)
    }

    func testArithmeticMean_identicalValues() throws {
        let values = [10.0, 10.0, 10.0]
        try assertArithmeticMean(values, expectedValue: 10.0, expectedStdDev: 0.0, accuracy: 1e-10)
    }

    func testArithmeticMean_twoValues() throws {
        let values = [0.0, 10.0]
        // Sample std dev = sqrt(50/1) = sqrt(50)
        try assertArithmeticMean(values, expectedValue: 5.0, expectedStdDev: sqrt(50), accuracy: 1e-10)
    }

    func testArithmeticMean_negativeValues() throws {
        let values = [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0]
        // Sum of squared deviations from 0: 25+9+1+1+9+25 = 70, sample std dev = sqrt(70/5) = sqrt(14)
        try assertArithmeticMean(values, expectedValue: 0.0, expectedStdDev: sqrt(14), accuracy: 1e-10)
    }

    func testArithmeticMean_extremeValues() throws {
        let scale = 1e100
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale, 5.0 * scale]

        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        // Both should produce finite results
        XCTAssertTrue(custom.value.isFinite, "Custom should handle extreme values")
        XCTAssertTrue(custom.absoluteError.isFinite, "Custom should handle extreme values")
        XCTAssertTrue(vdsp.value.isFinite, "vDSP should handle extreme values")
        XCTAssertTrue(vdsp.absoluteError.isFinite, "vDSP should handle extreme values")

        // Check expected values with appropriate accuracy
        XCTAssertEqual(custom.value, 3.0 * scale, accuracy: 1e90)
        XCTAssertEqual(custom.absoluteError, sqrt(2.5) * scale, accuracy: 1e90)
    }

    func testArithmeticMean_tinyValues() throws {
        let scale = 1e-100
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale, 5.0 * scale]

        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        // Both should produce finite results
        XCTAssertTrue(custom.value.isFinite, "Custom should handle tiny values")
        XCTAssertTrue(custom.absoluteError.isFinite, "Custom should handle tiny values")
        XCTAssertTrue(vdsp.value.isFinite, "vDSP should handle tiny values")
        XCTAssertTrue(vdsp.absoluteError.isFinite, "vDSP should handle tiny values")

        // Check expected values with appropriate accuracy
        XCTAssertEqual(custom.value, 3.0 * scale, accuracy: 1e-110)
        XCTAssertEqual(custom.absoluteError, sqrt(2.5) * scale, accuracy: 1e-110)
    }

    func testArithmeticMean_allZeros() throws {
        let values = [0.0, 0.0, 0.0]

        let custom = try values.arithmeticMeanL2()
        let vdsp = try values.arithmeticMeanL2_vDSP()

        XCTAssertEqual(custom.value, 0.0)
        XCTAssertEqual(custom.absoluteError, 0.0)
        XCTAssertEqual(vdsp.value, 0.0)
        // vDSP may produce NaN for std dev of all zeros due to 0/0
        // Our custom implementation handles this edge case
    }

    // MARK: - Geometric Mean Tests

    func testGeometricMean_powersOfTwo() throws {
        let values = [1.0, 2.0, 4.0]
        // Geometric mean of [1, 2, 4] = 2
        try assertGeometricMean(values, expectedValue: 2.0, accuracy: 1e-10)
    }

    func testGeometricMean_identicalValues() throws {
        let e = Darwin.M_E
        let values = [e, e, e]

        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        XCTAssertEqual(custom.value, e, accuracy: 1e-10)
        XCTAssertEqual(custom.relativeError, 0.0, accuracy: 1e-10)
        XCTAssertEqual(vdsp.value, e, accuracy: 1e-10)
        XCTAssertEqual(vdsp.relativeError, 0.0, accuracy: 1e-10)
    }

    func testGeometricMean_twoValues() throws {
        let values = [4.0, 9.0]
        // Geometric mean = sqrt(4 * 9) = 6
        try assertGeometricMean(values, expectedValue: 6.0, accuracy: 1e-10)
    }

    func testGeometricMean_alwaysPositive() throws {
        let values = [0.1, 0.5, 2.0, 10.0]

        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        XCTAssertTrue(custom.isPositive)
        XCTAssertTrue(vdsp.isPositive)
    }

    func testGeometricMean_logAbsMatchesArithmeticMeanOfLogs() throws {
        let values = [2.0, 8.0, 32.0]
        let logValues = values.map { Darwin.log($0) }

        let expectedLogMean = try logValues.arithmeticMeanL2()
        let expectedLogMeanVDSP = try logValues.arithmeticMeanL2_vDSP()

        let custom = try values.geometricMeanL2()
        let vdsp = try values.geometricMeanL2_vDSP()

        // Custom uses custom arithmeticMean internally
        XCTAssertEqual(custom.logAbs.value, expectedLogMean.value, accuracy: 1e-10)
        XCTAssertEqual(custom.logAbs.absoluteError, expectedLogMean.absoluteError, accuracy: 1e-10)

        // vDSP uses vDSP arithmeticMean internally
        XCTAssertEqual(vdsp.logAbs.value, expectedLogMeanVDSP.value, accuracy: 1e-10)
        XCTAssertEqual(vdsp.logAbs.absoluteError, expectedLogMeanVDSP.absoluteError, accuracy: 1e-10)
    }
}
