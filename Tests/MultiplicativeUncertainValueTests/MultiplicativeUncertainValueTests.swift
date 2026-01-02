//
//  MultiplicativeUncertainValueTests.swift
//  MultiplicativeUncertainValueTests
//
//  Tests for MultiplicativeUncertainValue and conversions.
//

import XCTest
import Darwin
@testable import MultiplicativeUncertainValue
@testable import UncertainValueCore

final class MultiplicativeUncertainValueTests: XCTestCase {
    // MARK: - Positive Value Initialization

    func testPositiveValueInit() {
        let value = 10.0
        let multError = 1.2
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        XCTAssertEqual(muv.sign, .plus)
        XCTAssertEqual(muv.logAbs.value, Darwin.log(value), accuracy: 1e-10)
        XCTAssertEqual(muv.logAbs.absoluteError, Darwin.log(multError), accuracy: 1e-10)
        XCTAssertEqual(muv.value, value, accuracy: 1e-10)
        XCTAssertEqual(muv.multiplicativeError, multError, accuracy: 1e-10)
    }

    func testPositiveValueMultiplicativeErrorReconstruction() {
        let value = 5.0
        let multError = 1.5
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        let reconstructedMultError = Darwin.exp(muv.logAbs.absoluteError)
        XCTAssertEqual(reconstructedMultError, multError, accuracy: 1e-10)
    }

    // MARK: - Negative Value Initialization

    func testNegativeValueInit() {
        let value = -10.0
        let multError = 1.2
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        XCTAssertEqual(muv.sign, .minus)
        XCTAssertEqual(muv.logAbs.value, Darwin.log(abs(value)), accuracy: 1e-10)
        XCTAssertEqual(muv.logAbs.absoluteError, Darwin.log(multError), accuracy: 1e-10)
        XCTAssertEqual(muv.value, value, accuracy: 1e-10)
        XCTAssertEqual(muv.multiplicativeError, multError, accuracy: 1e-10)
    }

    func testNegativeValueReconstruction() {
        let value = -7.5
        let multError = 1.1
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        XCTAssertEqual(muv.value, value, accuracy: 1e-10)
        XCTAssertEqual(muv.sign, .minus)
    }

    // MARK: - Relative Error

    func testRelativeErrorEqualsMultiplicativeErrorMinusOne() {
        let value = 100.0
        let multError = 1.25
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        XCTAssertEqual(muv.relativeError, multError - 1, accuracy: 1e-10)
        XCTAssertEqual(muv.relativeError, 0.25, accuracy: 1e-10)
    }

    func testRelativeErrorForVariousMultiplicativeErrors() {
        let testCases: [(Double, Double)] = [
            (1.0, 0.0),
            (1.1, 0.1),
            (2.0, 1.0),
            (1.05, 0.05)
        ]

        for (multError, expectedRelError) in testCases {
            let muv = MultiplicativeUncertainValue(value: 50.0, multiplicativeError: multError)
            XCTAssertEqual(muv.relativeError, expectedRelError, accuracy: 1e-10,
                          "For multError=\(multError), expected relError=\(expectedRelError)")
        }
    }

    // MARK: - Conversion from UncertainValue (Positive)

    func testConversionFromPositiveUncertainValue() {
        let uv = UncertainValue(10.0, absoluteError: 0.5)
        guard let muv = uv.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }

        XCTAssertEqual(muv.sign, .plus)
        XCTAssertEqual(muv.value, uv.value, accuracy: 1e-10)

        let expectedMultError = 1 + uv.relativeError
        XCTAssertEqual(muv.multiplicativeError, expectedMultError, accuracy: 1e-10)
    }

    func testConversionFromPositiveUncertainValueWithZeroError() {
        let uv = UncertainValue(20.0, absoluteError: 0.0)
        guard let muv = uv.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }

        XCTAssertEqual(muv.sign, .plus)
        XCTAssertEqual(muv.value, 20.0, accuracy: 1e-10)
        XCTAssertEqual(muv.multiplicativeError, 1.0, accuracy: 1e-10)
        XCTAssertEqual(muv.relativeError, 0.0, accuracy: 1e-10)
    }

    // MARK: - Conversion from UncertainValue (Negative)

    func testConversionFromNegativeUncertainValue() {
        let uv = UncertainValue(-10.0, absoluteError: 0.5)
        guard let muv = uv.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }

        XCTAssertEqual(muv.sign, .minus)
        XCTAssertEqual(muv.value, uv.value, accuracy: 1e-10)

        let expectedMultError = 1 + uv.relativeError
        XCTAssertEqual(muv.multiplicativeError, expectedMultError, accuracy: 1e-10)
    }

    func testConversionFromNegativeUncertainValuePreservesSign() {
        let uv = UncertainValue(-7.5, absoluteError: 0.375)
        guard let muv = uv.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }

        XCTAssertEqual(muv.sign, .minus)
        XCTAssertEqual(muv.value, -7.5, accuracy: 1e-10)
    }

    // MARK: - Conversion from UncertainValue (Zero)

    func testConversionFromZeroValueReturnsNil() {
        let uv = UncertainValue(0.0, absoluteError: 0.5)
        let muv = uv.asMultiplicative

        XCTAssertNil(muv, "Converting zero value should return nil")
    }

    func testConversionFromExactZeroReturnsNil() {
        let uv = UncertainValue(0.0, absoluteError: 0.0)
        let muv = uv.asMultiplicative

        XCTAssertNil(muv, "Converting exact zero should return nil")
    }

    // MARK: - Round-trip Conversion

    func testRoundTripConversionPositive() {
        let original = UncertainValue(15.0, absoluteError: 0.75)
        guard let muv = original.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }
        let roundTrip = muv.asUncertainValue

        XCTAssertEqual(roundTrip.value, original.value, accuracy: 1e-10)
        XCTAssertEqual(roundTrip.absoluteError, original.absoluteError, accuracy: 1e-10)
    }

    func testRoundTripConversionNegative() {
        let original = UncertainValue(-15.0, absoluteError: 0.75)
        guard let muv = original.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }
        let roundTrip = muv.asUncertainValue

        XCTAssertEqual(roundTrip.value, original.value, accuracy: 1e-10)
        XCTAssertEqual(roundTrip.absoluteError, original.absoluteError, accuracy: 1e-10)
    }

    func testRoundTripPreservesRelativeError() {
        let original = UncertainValue(100.0, absoluteError: 5.0)
        guard let muv = original.asMultiplicative else {
            XCTFail("Conversion should succeed for non-zero value")
            return
        }
        let roundTrip = muv.asUncertainValue

        XCTAssertEqual(roundTrip.relativeError, original.relativeError, accuracy: 1e-10)
    }

    // MARK: - Conversion Back to UncertainValue

    func testAsUncertainValuePositive() {
        let muv = MultiplicativeUncertainValue(value: 10.0, multiplicativeError: 1.2)
        let uv = muv.asUncertainValue

        XCTAssertEqual(uv.value, 10.0, accuracy: 1e-10)
        XCTAssertEqual(uv.relativeError, muv.relativeError, accuracy: 1e-10)
    }

    func testAsUncertainValueNegative() {
        let muv = MultiplicativeUncertainValue(value: -10.0, multiplicativeError: 1.2)
        let uv = muv.asUncertainValue

        XCTAssertEqual(uv.value, -10.0, accuracy: 1e-10)
        XCTAssertEqual(uv.relativeError, muv.relativeError, accuracy: 1e-10)
    }

    func testAsUncertainValuePreservesSignInValue() {
        let muvPositive = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.1)
        let muvNegative = MultiplicativeUncertainValue(value: -5.0, multiplicativeError: 1.1)

        XCTAssertGreaterThan(muvPositive.asUncertainValue.value, 0)
        XCTAssertLessThan(muvNegative.asUncertainValue.value, 0)
    }

    // MARK: - Edge Cases

    func testMinimalMultiplicativeError() {
        let muv = MultiplicativeUncertainValue(value: 10.0, multiplicativeError: 1.0)

        XCTAssertEqual(muv.multiplicativeError, 1.0, accuracy: 1e-10)
        XCTAssertEqual(muv.relativeError, 0.0, accuracy: 1e-10)
    }

    func testVerySmallPositiveValue() {
        let value = 1e-10
        let multError = 1.5
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        XCTAssertEqual(muv.value, value, accuracy: 1e-20)
        XCTAssertEqual(muv.multiplicativeError, multError, accuracy: 1e-10)
    }

    func testVeryLargePositiveValue() {
        let value = 1e10
        let multError = 1.5
        let muv = MultiplicativeUncertainValue(value: value, multiplicativeError: multError)

        XCTAssertEqual(muv.value, value, accuracy: 1e0)
        XCTAssertEqual(muv.multiplicativeError, multError, accuracy: 1e-10)
    }

    // MARK: - Sign Property

    func testSignPropertyPositive() {
        let muv = MultiplicativeUncertainValue(value: 42.0, multiplicativeError: 1.1)
        XCTAssertEqual(muv.sign, .plus)
    }

    func testSignPropertyNegative() {
        let muv = MultiplicativeUncertainValue(value: -42.0, multiplicativeError: 1.1)
        XCTAssertEqual(muv.sign, .minus)
    }

    // MARK: - Multiple Conversions

    func testMultipleRoundTrips() {
        var uv = UncertainValue(10.0, absoluteError: 0.5)

        for i in 0..<5 {
            guard let muv = uv.asMultiplicative else {
                XCTFail("Conversion failed at iteration \(i)")
                return
            }
            uv = muv.asUncertainValue
        }

        XCTAssertEqual(uv.value, 10.0, accuracy: 1e-8)
        XCTAssertEqual(uv.absoluteError, 0.5, accuracy: 1e-8)
    }

    func testConversionWorksForVerySmallNonZeroValue() {
        let uv = UncertainValue(1e-100, absoluteError: 1e-101)
        guard let muv = uv.asMultiplicative else {
            XCTFail("Should convert very small non-zero values")
            return
        }

        XCTAssertEqual(muv.sign, .plus)
    }

    func testConversionWorksForVerySmallNegativeValue() {
        let uv = UncertainValue(-1e-100, absoluteError: 1e-101)
        guard let muv = uv.asMultiplicative else {
            XCTFail("Should convert very small negative non-zero values")
            return
        }

        XCTAssertEqual(muv.sign, .minus)
    }

    // MARK: - Finiteness Handling in Conversion

    func testConversionReturnsNilForNaN() {
        let uv = UncertainValue(.nan, absoluteError: 0.5)
        let muv = uv.asMultiplicative

        XCTAssertNil(muv, "Converting NaN should return nil")
    }

    func testConversionReturnsNilForInfinity() {
        let uv = UncertainValue(.infinity, absoluteError: 0.5)
        let muv = uv.asMultiplicative

        XCTAssertNil(muv, "Converting infinity should return nil")
    }

    func testConversionReturnsNilForNegativeInfinity() {
        let uv = UncertainValue(-.infinity, absoluteError: 0.5)
        let muv = uv.asMultiplicative

        XCTAssertNil(muv, "Converting negative infinity should return nil")
    }

    func testConversionReturnsNilWhenMultiplicativeErrorWouldBeInvalid() {
        // Create an UncertainValue where 1 + relativeError would be < 1
        // This can happen if relativeError is very negative (though unusual)
        let uv = UncertainValue(10.0, absoluteError: .infinity)
        let muv = uv.asMultiplicative

        XCTAssertNil(muv, "Converting with non-finite error should return nil")
    }
}
