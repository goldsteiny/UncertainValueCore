//
//  UncertainValueStatisticsExtensionTests.swift
//  UncertainValueCoreTests
//
//  Tests for [UncertainValue] extensions from UncertainValueStatistics.
//

import Foundation
import Testing
@testable import UncertainValueCore
@testable import UncertainValueStatistics

struct UncertainValueStatisticsExtensionTests {

    // MARK: - [UncertainValue] Arithmetic Mean Tests

    @Test func arithmeticMeanL2() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = try? values.arithmeticMeanL2()

        #expect(result != nil)
        #expect(result!.value == 15.0)
        // sum error L2: sqrt(0.3^2 + 0.4^2) = 0.5, then / 2 = 0.25
        #expect(abs(result!.absoluteError - 0.25) < 0.0001)
    }

    @Test func arithmeticMeanSingleElement() {
        let values = [UncertainValue(10.0, absoluteError: 0.5)]
        let result = try? values.arithmeticMeanL2()
        
        #expect(result != nil)
        #expect(result!.value == 10.0)
        #expect(result!.absoluteError == 0.5)
    }

    @Test func arithmeticMeanAllNegativeValues() {
        let values = [
            UncertainValue(-10.0, absoluteError: 0.3),
            UncertainValue(-20.0, absoluteError: 0.4)
        ]
        let result = try? values.arithmeticMeanL2()
        
        #expect(result != nil)
        #expect(result!.value == -15.0)
        #expect(abs(result!.absoluteError - 0.25) < 0.0001)
    }

    @Test func arithmeticMeanManyElements() {
        let values = [
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.1),
            UncertainValue(3.0, absoluteError: 0.1),
            UncertainValue(4.0, absoluteError: 0.1),
            UncertainValue(5.0, absoluteError: 0.1)
        ]
        let result = try? values.arithmeticMeanL2()
        
        #expect(result != nil)
        #expect(result!.value == 3.0)
        // sum error L2: sqrt(5 * 0.1^2) = sqrt(0.05), then / 5
        let expectedError = sqrt(5.0 * 0.01) / 5.0
        #expect(abs(result!.absoluteError - expectedError) < 0.0001)
    }

    // MARK: - [Double] Sample Standard Deviation Tests

    @Test func sampleStdDevSimpleSequence() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        // Mean = 3, deviations = [-2, -1, 0, 1, 2]
        // Sum of squares = 4 + 1 + 0 + 1 + 4 = 10
        // Sample variance = 10 / 4 = 2.5
        // Sample std dev = sqrt(2.5)
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(abs(result! - sqrt(2.5)) < 1e-10)
    }

    @Test func sampleStdDevTwoElements() {
        let values = [0.0, 10.0]
        // Mean = 5, deviations = [-5, 5]
        // Sum of squares = 50
        // Sample variance = 50 / 1 = 50
        // Sample std dev = sqrt(50)
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(abs(result! - sqrt(50)) < 1e-10)
    }

    @Test func sampleStdDevIdenticalValues() {
        let values = [7.0, 7.0, 7.0, 7.0]
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(result! == 0.0)
    }

    @Test func sampleStdDevNegativeValues() {
        let values = [-5.0, -3.0, -1.0, 1.0, 3.0, 5.0]
        // Mean = 0, deviations = [-5, -3, -1, 1, 3, 5]
        // Sum of squares = 25 + 9 + 1 + 1 + 9 + 25 = 70
        // Sample variance = 70 / 5 = 14
        // Sample std dev = sqrt(14)
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(abs(result! - sqrt(14)) < 1e-10)
    }

    @Test func sampleStdDevLargeValues() {
        let scale = 1e50
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale]
        // Should scale linearly
        let unscaled = try? [1.0, 2.0, 3.0].sampleStandardDeviationL2()
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(unscaled != nil)
        #expect(abs(result! - unscaled! * scale) < 1e40)
    }

    @Test func sampleStdDevTinyValues() {
        let scale = 1e-50
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale]
        let unscaled = try? [1.0, 2.0, 3.0].sampleStandardDeviationL2()
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(unscaled != nil)
        #expect(abs(result! - unscaled! * scale) < 1e-60)
    }

    @Test func sampleStdDevSymmetricAroundZero() {
        let values = [-2.0, -1.0, 0.0, 1.0, 2.0]
        // Mean = 0, sum of squares = 10, sample var = 10/4 = 2.5
        let result = try? values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(abs(result! - sqrt(2.5)) < 1e-10)
    }

    // MARK: - [Double] Arithmetic Mean (returns UncertainValue) Tests

    @Test func doubleArithmeticMeanValue() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let result = try? values.arithmeticMeanL2()
        #expect(result != nil)
        #expect(result!.value == 3.0)
    }

    @Test func doubleArithmeticMeanErrorIsSampleStdDev() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let result = try? values.arithmeticMeanL2()
        let expectedStdDev = try! values.sampleStandardDeviationL2()
        #expect(result != nil)
        #expect(abs(result!.absoluteError - expectedStdDev) < 1e-10)
    }

    @Test func doubleArithmeticMeanIdenticalValues() {
        let values = [5.0, 5.0, 5.0]
        let result = try? values.arithmeticMeanL2()
        #expect(result != nil)
        #expect(result!.value == 5.0)
        #expect(result!.absoluteError == 0.0)
    }

    @Test func doubleArithmeticMeanNegativeValues() {
        let values = [-10.0, -20.0, -30.0]
        let result = try? values.arithmeticMeanL2()
        let expected = try? values.sampleStandardDeviationL2()
        #expect(result != nil)
        #expect(expected != nil)
        #expect(result!.value == -20.0)
        #expect(result!.absoluteError == expected)
    }

    @Test func doubleArithmeticMeanMixedSigns() {
        let values = [-10.0, 0.0, 10.0]
        let result = try? values.arithmeticMeanL2()
        #expect(result != nil)
        #expect(result!.value == 0.0)
        #expect(result!.absoluteError == 10.0)  // sqrt(200/2) = 10
    }

    // MARK: - [UncertainValue] Sample Standard Deviation Tests

    @Test func uncertainValueSampleStdDevBasic() {
        let values = [
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.1),
            UncertainValue(3.0, absoluteError: 0.1)
        ]
        let result = try? values.sampleStandardDeviationL2()

        // Value should match [Double] version
        let expectedValue = try? values.values.sampleStandardDeviationL2()
        
        #expect(result != nil)
        #expect(expectedValue != nil)
        #expect(abs(result!.value - expectedValue!) < 1e-10)

        // Error calculation:
        // n=3, mean=2, deviations=[-1, 0, 1], sqrt(n-1)=sqrt(2)
        // scaledDeviations = [-1/sqrt(2), 0, 1/sqrt(2)]
        // scaledErrors = [(-1/sqrt(2))*0.1, 0, (1/sqrt(2))*0.1]
        // resultError = norm2(scaledErrors) = sqrt(2 * (0.1/sqrt(2))^2) = sqrt(0.01) = 0.1
        #expect(abs(result!.absoluteError - 0.1) < 1e-10)
    }

    @Test func uncertainValueSampleStdDevIdenticalValues() {
        let values = [
            UncertainValue(5.0, absoluteError: 0.1),
            UncertainValue(5.0, absoluteError: 0.1),
            UncertainValue(5.0, absoluteError: 0.1)
        ]
        
        let result = try? values.sampleStandardDeviationL2()
        #expect(result != nil)
        #expect(result!.value == 0.0)
    }

    @Test func uncertainValueSampleStdDevErrorPropagation() {
        // When all values are identical, deviations are 0
        // so error contribution should also be 0
        let values = [
            UncertainValue(5.0, absoluteError: 0.5),
            UncertainValue(5.0, absoluteError: 0.5),
            UncertainValue(5.0, absoluteError: 0.5)
        ]
        let result = try? values.sampleStandardDeviationL2()
        #expect(result != nil)
        #expect(result!.value == 0.0)
        #expect(result!.absoluteError == 0.0)
    }

    @Test func uncertainValueSampleStdDevNonZeroError() {
        // Values with spread should have non-zero error
        let values = [
            UncertainValue(0.0, absoluteError: 0.1),
            UncertainValue(10.0, absoluteError: 0.1)
        ]
        let result = try? values.sampleStandardDeviationL2()
        #expect(result != nil)

        // Value = sqrt(50) ≈ 7.07
        #expect(abs(result!.value - sqrt(50)) < 1e-10)

        // Error calculation:
        // n=2, mean=5, deviations=[-5, 5], sqrt(n-1)=1
        // scaledDeviations = [-5, 5]
        // scaledErrors = [-5*0.1, 5*0.1] = [-0.5, 0.5]
        // resultError = norm2([-0.5, 0.5]) = sqrt(0.5) ≈ 0.707
        #expect(abs(result!.absoluteError - sqrt(0.5)) < 1e-10)
    }

    @Test func uncertainValueSampleStdDevSymmetric() {
        let values = [
            UncertainValue(-2.0, absoluteError: 0.1),
            UncertainValue(-1.0, absoluteError: 0.1),
            UncertainValue(0.0, absoluteError: 0.1),
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.1)
        ]
        let result = try? values.sampleStandardDeviationL2()

        let expectedValue = try? values.values.sampleStandardDeviationL2()
        #expect(result != nil)
        #expect(expectedValue != nil)
        #expect(abs(result!.value - expectedValue!) < 1e-10)

        // Error calculation:
        // n=5, mean=0, deviations=[-2, -1, 0, 1, 2], sqrt(n-1)=2
        // scaledDeviations = [-1, -0.5, 0, 0.5, 1]
        // scaledErrors = [-0.1, -0.05, 0, 0.05, 0.1]
        // resultError = norm2 = sqrt(0.01 + 0.0025 + 0 + 0.0025 + 0.01) = sqrt(0.025)
        #expect(abs(result!.absoluteError - sqrt(0.025)) < 1e-10)
    }

    @Test func uncertainValueSampleStdDevLargerErrorsGiveLargerUncertainty() {
        let smallErrors = [
            UncertainValue(1.0, absoluteError: 0.01),
            UncertainValue(2.0, absoluteError: 0.01),
            UncertainValue(3.0, absoluteError: 0.01)
        ]
        let largeErrors = [
            UncertainValue(1.0, absoluteError: 1.0),
            UncertainValue(2.0, absoluteError: 1.0),
            UncertainValue(3.0, absoluteError: 1.0)
        ]

        let smallResult = try? smallErrors.sampleStandardDeviationL2()
        let largeResult = try? largeErrors.sampleStandardDeviationL2()

        // Same central value
        #expect(smallResult != nil)
        #expect(largeResult != nil)
        #expect(smallResult!.value == largeResult!.value)
        // Larger input errors -> larger output error
        #expect(largeResult!.absoluteError > smallResult!.absoluteError)

        // Error scales linearly with input errors
        // n=3, mean=2, deviations=[-1, 0, 1], sqrt(n-1)=sqrt(2)
        // scaledDeviations = [-1/sqrt(2), 0, 1/sqrt(2)]
        // For error=e: scaledErrors = [-e/sqrt(2), 0, e/sqrt(2)]
        // resultError = norm2 = sqrt(2 * (e/sqrt(2))^2) = e
        #expect(abs(smallResult!.absoluteError - 0.01) < 1e-10)
        #expect(abs(largeResult!.absoluteError - 1.0) < 1e-10)
    }

    @Test func uncertainValueSampleStdDevZeroInputErrors() {
        let values = [
            UncertainValue.one,
            UncertainValue(2.0, absoluteError: 0.0),
            UncertainValue(3.0, absoluteError: 0.0)
        ]
        let result = try? values.sampleStandardDeviationL2()
        let expected = try? values.values.sampleStandardDeviationL2()

        #expect(result != nil)
        #expect(expected != nil)
        // With zero input errors, output error should be zero
        #expect(result!.absoluteError == 0.0)
        // But value should still be computed
        #expect(result!.value == expected!)
    }

    // MARK: - Cross-validation Tests

    @Test func arithmeticMeanMatchesvDSP() {
        let values = [1.5, 2.7, 3.2, 4.8, 5.1]
        let custom = try? values.arithmeticMeanL2()
        let vdsp = try? values.arithmeticMeanL2_vDSP()

        #expect(custom != nil)
        #expect(vdsp != nil)
        #expect(abs(custom!.value - vdsp!.value) < 1e-10)
        #expect(abs(custom!.absoluteError - vdsp!.absoluteError) < 1e-10)
    }

    @Test func arithmeticMeanMatchesvDSPExtremeValues() {
        let values = [1e100, 2e100, 3e100]
        let custom = try? values.arithmeticMeanL2()
        let vdsp = try? values.arithmeticMeanL2_vDSP()

        #expect(custom != nil)
        #expect(vdsp != nil)

        // Both should be finite
        #expect(custom!.value.isFinite)
        #expect(vdsp!.value.isFinite)
        // And match closely
        #expect(abs(custom!.value - vdsp!.value) / custom!.value < 1e-10)
    }
}
