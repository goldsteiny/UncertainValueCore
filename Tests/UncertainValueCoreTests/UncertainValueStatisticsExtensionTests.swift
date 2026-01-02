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

    // MARK: - Arithmetic Mean Tests

    @Test func arithmeticMean() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.arithmeticMean()

        #expect(result.value == 15.0)
        // sum error L2: sqrt(0.3^2 + 0.4^2) = 0.5, then / 2 = 0.25
        #expect(abs(result.absoluteError - 0.25) < 0.0001)
    }

    @Test func arithmeticMeanSingleElement() {
        let values = [UncertainValue(10.0, absoluteError: 0.5)]
        let result = values.arithmeticMean()

        #expect(result.value == 10.0)
        #expect(result.absoluteError == 0.5)
    }

    @Test func arithmeticMeanAllNegativeValues() {
        let values = [
            UncertainValue(-10.0, absoluteError: 0.3),
            UncertainValue(-20.0, absoluteError: 0.4)
        ]
        let result = values.arithmeticMean()

        #expect(result.value == -15.0)
        #expect(abs(result.absoluteError - 0.25) < 0.0001)
    }
}
