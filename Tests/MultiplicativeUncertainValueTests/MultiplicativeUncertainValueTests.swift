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

    // MARK: - Log-Space Initializer

    func testLogSpaceInitializer() {
        let logAbs = UncertainValue(Darwin.log(2.0), absoluteError: Darwin.log(1.1))
        let muv = MultiplicativeUncertainValue(logAbs: logAbs, sign: .plus)

        XCTAssertEqual(muv.value, 2.0, accuracy: 1e-10)
        XCTAssertEqual(muv.multiplicativeError, 1.1, accuracy: 1e-10)
        XCTAssertEqual(muv.sign, .plus)
    }

    func testLogSpaceInitializerNegativeSign() {
        let logAbs = UncertainValue(Darwin.log(3.0), absoluteError: Darwin.log(1.2))
        let muv = MultiplicativeUncertainValue(logAbs: logAbs, sign: .minus)

        XCTAssertEqual(muv.value, -3.0, accuracy: 1e-10)
        XCTAssertEqual(muv.sign, .minus)
    }

    // MARK: - Static exp Constructor

    func testExpDefaultSignCreatesPositive() {
        let logAbs = UncertainValue(Darwin.log(4.0), absoluteError: Darwin.log(1.2))
        let muv = MultiplicativeUncertainValue.exp(logAbs)

        XCTAssertEqual(muv.value, 4.0, accuracy: 1e-10)
        XCTAssertEqual(muv.sign, .plus)
    }

    func testExpWithMinusSignCreatesNegative() {
        let logAbs = UncertainValue(Darwin.log(4.0), absoluteError: Darwin.log(1.2))
        let muv = MultiplicativeUncertainValue.exp(logAbs, withResultSign: .minus)

        XCTAssertEqual(muv.value, -4.0, accuracy: 1e-10)
        XCTAssertEqual(muv.sign, .minus)
    }

    func testExpPreservesLogAbs() {
        let logAbs = UncertainValue(Darwin.log(5.0), absoluteError: Darwin.log(1.3))
        let muv = MultiplicativeUncertainValue.exp(logAbs, withResultSign: .plus)

        XCTAssertEqual(muv.logAbs.value, logAbs.value, accuracy: 1e-10)
        XCTAssertEqual(muv.logAbs.absoluteError, logAbs.absoluteError, accuracy: 1e-10)
    }

    // MARK: - Reciprocal

    func testReciprocalValue() {
        let muv = MultiplicativeUncertainValue(value: 2.0, multiplicativeError: 1.1)
        let reciprocal = muv.reciprocal

        XCTAssertEqual(reciprocal.value, 0.5, accuracy: 1e-10)
    }

    func testReciprocalPreservesSign() {
        let positive = MultiplicativeUncertainValue(value: 2.0, multiplicativeError: 1.1)
        let negative = MultiplicativeUncertainValue(value: -2.0, multiplicativeError: 1.1)

        XCTAssertEqual(positive.reciprocal.sign, .plus)
        XCTAssertEqual(negative.reciprocal.sign, .minus)
    }

    func testReciprocalLogAbsNegated() {
        let muv = MultiplicativeUncertainValue(value: 2.0, multiplicativeError: 1.1)
        let reciprocal = muv.reciprocal

        XCTAssertEqual(reciprocal.logAbs.value, -muv.logAbs.value, accuracy: 1e-10)
        XCTAssertEqual(reciprocal.logAbs.absoluteError, muv.logAbs.absoluteError, accuracy: 1e-10)
    }

    func testReciprocalOfReciprocal() {
        let muv = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.2)
        let doubleReciprocal = muv.reciprocal.reciprocal

        XCTAssertEqual(doubleReciprocal.value, muv.value, accuracy: 1e-10)
        XCTAssertEqual(doubleReciprocal.multiplicativeError, muv.multiplicativeError, accuracy: 1e-10)
    }

    // MARK: - Negative

    func testNegativeFlipsValue() {
        let muv = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.1)
        let neg = muv.negative

        XCTAssertEqual(neg.value, -5.0, accuracy: 1e-10)
    }

    func testNegativeFlipsSign() {
        let positive = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.1)
        let negative = MultiplicativeUncertainValue(value: -5.0, multiplicativeError: 1.1)

        XCTAssertEqual(positive.negative.sign, .minus)
        XCTAssertEqual(negative.negative.sign, .plus)
    }

    func testNegativePreservesLogAbs() {
        let muv = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.1)
        let neg = muv.negative

        XCTAssertEqual(neg.logAbs.value, muv.logAbs.value, accuracy: 1e-10)
        XCTAssertEqual(neg.logAbs.absoluteError, muv.logAbs.absoluteError, accuracy: 1e-10)
    }

    func testDoubleNegative() {
        let muv = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.1)
        let doubleNeg = muv.negative.negative

        XCTAssertEqual(doubleNeg.value, muv.value, accuracy: 1e-10)
        XCTAssertEqual(doubleNeg.sign, muv.sign)
    }

    // MARK: - Absolute Value

    func testAbsValuePositive() {
        let muv = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.1)
        let abs = muv.absValue

        XCTAssertEqual(abs.value, 5.0, accuracy: 1e-10)
        XCTAssertEqual(abs.sign, .plus)
    }

    func testAbsValueNegative() {
        let muv = MultiplicativeUncertainValue(value: -5.0, multiplicativeError: 1.1)
        let abs = muv.absValue

        XCTAssertEqual(abs.value, 5.0, accuracy: 1e-10)
        XCTAssertEqual(abs.sign, .plus)
    }

    func testAbsValuePreservesLogAbs() {
        let muv = MultiplicativeUncertainValue(value: -5.0, multiplicativeError: 1.1)
        let abs = muv.absValue

        XCTAssertEqual(abs.logAbs.value, muv.logAbs.value, accuracy: 1e-10)
        XCTAssertEqual(abs.logAbs.absoluteError, muv.logAbs.absoluteError, accuracy: 1e-10)
    }

    func testAbsValueIdempotent() {
        let muv = MultiplicativeUncertainValue(value: -5.0, multiplicativeError: 1.1)
        let abs1 = muv.absValue
        let abs2 = abs1.absValue

        XCTAssertEqual(abs2.value, abs1.value, accuracy: 1e-10)
        XCTAssertEqual(abs2.sign, abs1.sign)
    }

    // MARK: - Raised to Integer Power

    func testRaisedToIntegerPowerPositive() {
        let muv = MultiplicativeUncertainValue(value: 2.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: 3) else {
            XCTFail("Should succeed for valid input")
            return
        }

        XCTAssertEqual(result.value, 8.0, accuracy: 1e-10)
        XCTAssertEqual(result.sign, .plus)
    }

    func testRaisedToEvenPowerBecomesPositive() {
        let muv = MultiplicativeUncertainValue(value: -2.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: 2) else {
            XCTFail("Should succeed for valid input")
            return
        }

        XCTAssertEqual(result.value, 4.0, accuracy: 1e-10)
        XCTAssertEqual(result.sign, .plus)
    }

    func testRaisedToOddPowerPreservesSign() {
        let muv = MultiplicativeUncertainValue(value: -2.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: 3) else {
            XCTFail("Should succeed for valid input")
            return
        }

        XCTAssertEqual(result.value, -8.0, accuracy: 1e-10)
        XCTAssertEqual(result.sign, .minus)
    }

    func testRaisedToZeroPower() {
        let muv = MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 1.2)
        guard let result = muv.raised(to: 0) else {
            XCTFail("Should succeed for valid input")
            return
        }

        XCTAssertEqual(result.value, 1.0, accuracy: 1e-10)
        XCTAssertEqual(result.sign, .plus)
    }

    func testRaisedToNegativeIntegerPower() {
        let muv = MultiplicativeUncertainValue(value: 2.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: -2) else {
            XCTFail("Should succeed for valid input")
            return
        }

        XCTAssertEqual(result.value, 0.25, accuracy: 1e-10)
    }

    func testRaisedToIntegerPowerLogAbsPropagation() {
        let muv = MultiplicativeUncertainValue(value: 2.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: 3) else {
            XCTFail("Should succeed for valid input")
            return
        }

        // logAbs should be scaled by 3
        XCTAssertEqual(result.logAbs.value, 3 * muv.logAbs.value, accuracy: 1e-10)
        XCTAssertEqual(result.logAbs.absoluteError, 3 * muv.logAbs.absoluteError, accuracy: 1e-10)
    }

    // MARK: - Raised to Real Power

    func testRaisedToRealPowerPositive() {
        let muv = MultiplicativeUncertainValue(value: 4.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: 0.5) else {
            XCTFail("Should succeed for positive value")
            return
        }

        XCTAssertEqual(result.value, 2.0, accuracy: 1e-10)
        XCTAssertEqual(result.sign, .plus)
    }

    func testRaisedToRealPowerNegativeReturnsNil() {
        let muv = MultiplicativeUncertainValue(value: -4.0, multiplicativeError: 1.1)
        let result = muv.raised(to: 0.5)

        XCTAssertNil(result, "Real power of negative value should return nil")
    }

    func testRaisedToRealPowerLogAbsPropagation() {
        let muv = MultiplicativeUncertainValue(value: 4.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: 2.5) else {
            XCTFail("Should succeed for positive value")
            return
        }

        XCTAssertEqual(result.logAbs.value, 2.5 * muv.logAbs.value, accuracy: 1e-10)
        XCTAssertEqual(result.logAbs.absoluteError, 2.5 * muv.logAbs.absoluteError, accuracy: 1e-10)
    }

    func testRaisedToNegativeRealPower() {
        let muv = MultiplicativeUncertainValue(value: 4.0, multiplicativeError: 1.1)
        guard let result = muv.raised(to: -0.5) else {
            XCTFail("Should succeed for positive value")
            return
        }

        XCTAssertEqual(result.value, 0.5, accuracy: 1e-10)
    }
}
