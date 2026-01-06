//
//  MultiplicativeUncertainValueTests.swift
//  MultiplicativeUncertainValueTests
//
//  Tests for MultiplicativeUncertainValue and conversions.
//

import Testing
import Darwin
@testable import MultiplicativeUncertainValue
@testable import UncertainValueCore
import UncertainValueCoreAlgebra

private let accuracy = 1e-10

@Suite struct MultiplicativeUncertainValueTests {
    // MARK: - Positive Value Initialization

    @Test func positiveValueInit() {
        let value = 10.0
        let multError = 1.2
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        #expect(muv.signum == .positive)
        #expect(abs(muv.logAbs.value - Darwin.log(value)) < accuracy)
        #expect(abs(muv.logAbs.absoluteError - Darwin.log(multError)) < accuracy)
        #expect(abs(muv.value - value) < accuracy)
        #expect(abs(muv.multiplicativeError - multError) < accuracy)
    }

    @Test func positiveValueMultiplicativeErrorReconstruction() {
        let value = 5.0
        let multError = 1.5
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        let reconstructedMultError = Darwin.exp(muv.logAbs.absoluteError)
        #expect(abs(reconstructedMultError - multError) < accuracy)
    }

    // MARK: - Negative Value Initialization

    @Test func negativeValueInit() {
        let value = -10.0
        let multError = 1.2
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        #expect(muv.signum == .negative)
        #expect(abs(muv.logAbs.value - Darwin.log(abs(value))) < accuracy)
        #expect(abs(muv.logAbs.absoluteError - Darwin.log(multError)) < accuracy)
        #expect(abs(muv.value - value) < accuracy)
        #expect(abs(muv.multiplicativeError - multError) < accuracy)
    }

    @Test func negativeValueReconstruction() {
        let value = -7.5
        let multError = 1.1
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        #expect(abs(muv.value - value) < accuracy)
        #expect(muv.signum == .negative)
    }

    // MARK: - Throwing Initializer Error Cases

    @Test func initWithZeroValueThrows() {
        #expect(throws: UncertainValueError.zeroInput) {
            try MultiplicativeUncertainValue(value: 0.0, multiplicativeError: 1.1)
        }
    }

    @Test func initWithNonFiniteValueThrows() {
        #expect(throws: UncertainValueError.nonFinite) {
            try MultiplicativeUncertainValue(value: .infinity, multiplicativeError: 1.1)
        }
    }

    @Test func initWithNaNValueThrows() {
        #expect(throws: UncertainValueError.nonFinite) {
            try MultiplicativeUncertainValue(value: .nan, multiplicativeError: 1.1)
        }
    }

    @Test func initWithMultiplicativeErrorLessThanOneThrows() {
        #expect(throws: UncertainValueError.invalidMultiplicativeError) {
            try MultiplicativeUncertainValue(value: 5.0, multiplicativeError: 0.9)
        }
    }

    @Test func initWithNonFiniteMultiplicativeErrorThrows() {
        #expect(throws: UncertainValueError.nonFinite) {
            try MultiplicativeUncertainValue(value: 5.0, multiplicativeError: .infinity)
        }
    }

    @Test func initLogAbsWithNonFiniteThrows() {
        let nonFiniteLogAbs = UncertainValue(.infinity, absoluteError: 0.1)
        #expect(throws: UncertainValueError.nonFinite) {
            try MultiplicativeUncertainValue(logAbs: nonFiniteLogAbs, signum: .positive)
        }
    }

    // MARK: - Relative Error

    @Test func relativeErrorEqualsMultiplicativeErrorMinusOne() {
        let value = 100.0
        let multError = 1.25
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        #expect(abs(muv.relativeError - (multError - 1)) < accuracy)
        #expect(abs(muv.relativeError - 0.25) < accuracy)
    }

    @Test func relativeErrorForVariousMultiplicativeErrors() {
        let testCases: [(Double, Double)] = [
            (1.0, 0.0),
            (1.1, 0.1),
            (2.0, 1.0),
            (1.05, 0.05)
        ]
        for (multError, expectedRelError) in testCases {
            let muv = MultiplicativeUncertainValue.unchecked(value: 50.0, multiplicativeError: multError)
            #expect(abs(muv.relativeError - expectedRelError) < accuracy)
        }
    }

    // MARK: - Conversion from UncertainValue (Positive)

    @Test func conversionFromPositiveUncertainValue() throws {
        let uv = UncertainValue(10.0, absoluteError: 0.5)
        let muv = try uv.asMultiplicative
        #expect(muv.signum == .positive)
        #expect(abs(muv.value - uv.value) < accuracy)
        let expectedMultError = 1 + uv.relativeError
        #expect(abs(muv.multiplicativeError - expectedMultError) < accuracy)
    }

    @Test func conversionFromPositiveUncertainValueWithZeroError() throws {
        let uv = UncertainValue(20.0, absoluteError: 0.0)
        let muv = try uv.asMultiplicative
        #expect(muv.signum == .positive)
        #expect(abs(muv.value - 20.0) < accuracy)
        #expect(abs(muv.multiplicativeError - 1.0) < accuracy)
        #expect(abs(muv.relativeError - 0.0) < accuracy)
    }

    // MARK: - Conversion from UncertainValue (Negative)

    @Test func conversionFromNegativeUncertainValue() throws {
        let uv = UncertainValue(-10.0, absoluteError: 0.5)
        let muv = try uv.asMultiplicative
        #expect(muv.signum == .negative)
        #expect(abs(muv.value - uv.value) < accuracy)
        let expectedMultError = 1 + uv.relativeError
        #expect(abs(muv.multiplicativeError - expectedMultError) < accuracy)
    }

    @Test func conversionFromNegativeUncertainValuePreservesSign() throws {
        let uv = UncertainValue(-7.5, absoluteError: 0.375)
        let muv = try uv.asMultiplicative
        #expect(muv.signum == .negative)
        #expect(abs(muv.value - (-7.5)) < accuracy)
    }

    // MARK: - Conversion from UncertainValue (Zero)

    @Test func conversionFromZeroValueThrows() {
        let uv = UncertainValue(0.0, absoluteError: 0.5)
        #expect(throws: UncertainValueError.self) {
            try uv.asMultiplicative
        }
    }

    @Test func conversionFromExactZeroThrows() {
        let uv = UncertainValue.zero
        #expect(throws: UncertainValueError.self) {
            try uv.asMultiplicative
        }
    }

    // MARK: - Round-trip Conversion

    @Test func roundTripConversionPositive() throws {
        let original = UncertainValue(15.0, absoluteError: 0.75)
        let muv = try original.asMultiplicative
        let roundTrip = muv.asUncertainValue
        #expect(abs(roundTrip.value - original.value) < accuracy)
        #expect(abs(roundTrip.absoluteError - original.absoluteError) < accuracy)
    }

    @Test func roundTripConversionNegative() throws {
        let original = UncertainValue(-15.0, absoluteError: 0.75)
        let muv = try original.asMultiplicative
        let roundTrip = muv.asUncertainValue
        #expect(abs(roundTrip.value - original.value) < accuracy)
        #expect(abs(roundTrip.absoluteError - original.absoluteError) < accuracy)
    }

    @Test func roundTripPreservesRelativeError() throws {
        let original = UncertainValue(100.0, absoluteError: 5.0)
        let muv = try original.asMultiplicative
        let roundTrip = muv.asUncertainValue
        #expect(abs(roundTrip.relativeError - original.relativeError) < accuracy)
    }

    // MARK: - Conversion Back to UncertainValue

    @Test func asUncertainValuePositive() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 10.0, multiplicativeError: 1.2)
        let uv = muv.asUncertainValue
        #expect(abs(uv.value - 10.0) < accuracy)
        #expect(abs(uv.relativeError - muv.relativeError) < accuracy)
    }

    @Test func asUncertainValueNegative() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -10.0, multiplicativeError: 1.2)
        let uv = muv.asUncertainValue
        #expect(abs(uv.value - (-10.0)) < accuracy)
        #expect(abs(uv.relativeError - muv.relativeError) < accuracy)
    }

    @Test func asUncertainValuePreservesSignInValue() {
        let muvPositive = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        let muvNegative = MultiplicativeUncertainValue.unchecked(value: -5.0, multiplicativeError: 1.1)
        #expect(muvPositive.asUncertainValue.value > 0)
        #expect(muvNegative.asUncertainValue.value < 0)
    }

    // MARK: - Edge Cases

    @Test func minimalMultiplicativeError() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 10.0, multiplicativeError: 1.0)
        #expect(abs(muv.multiplicativeError - 1.0) < accuracy)
        #expect(abs(muv.relativeError - 0.0) < accuracy)
    }

    @Test func verySmallPositiveValue() {
        let value = 1e-10
        let multError = 1.5
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        #expect(abs(muv.value - value) < 1e-20)
        #expect(abs(muv.multiplicativeError - multError) < accuracy)
    }

    @Test func veryLargePositiveValue() {
        let value = 1e10
        let multError = 1.5
        let muv = MultiplicativeUncertainValue.unchecked(value: value, multiplicativeError: multError)
        #expect(abs(muv.value - value) < 1e0)
        #expect(abs(muv.multiplicativeError - multError) < accuracy)
    }

    // MARK: - Signum Property

    @Test func signumPropertyPositive() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 42.0, multiplicativeError: 1.1)
        #expect(muv.signum == .positive)
    }

    @Test func signumPropertyNegative() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -42.0, multiplicativeError: 1.1)
        #expect(muv.signum == .negative)
    }

    // MARK: - Multiple Conversions

    @Test func multipleRoundTrips() throws {
        var uv = UncertainValue(10.0, absoluteError: 0.5)
        for _ in 0..<5 {
            let muv = try uv.asMultiplicative
            uv = muv.asUncertainValue
        }
        #expect(abs(uv.value - 10.0) < 1e-8)
        #expect(abs(uv.absoluteError - 0.5) < 1e-8)
    }

    @Test func conversionWorksForVerySmallNonZeroValue() throws {
        let uv = UncertainValue(1e-100, absoluteError: 1e-101)
        let muv = try uv.asMultiplicative
        #expect(muv.signum == .positive)
    }

    @Test func conversionWorksForVerySmallNegativeValue() throws {
        let uv = UncertainValue(-1e-100, absoluteError: 1e-101)
        let muv = try uv.asMultiplicative
        #expect(muv.signum == .negative)
    }

    // MARK: - Finiteness Handling in Conversion

    @Test func conversionThrowsForNaN() {
        let uv = UncertainValue(.nan, absoluteError: 0.5)
        #expect(throws: UncertainValueError.self) {
            try uv.asMultiplicative
        }
    }

    @Test func conversionThrowsForInfinity() {
        let uv = UncertainValue(.infinity, absoluteError: 0.5)
        #expect(throws: UncertainValueError.self) {
            try uv.asMultiplicative
        }
    }

    @Test func conversionThrowsForNegativeInfinity() {
        let uv = UncertainValue(-.infinity, absoluteError: 0.5)
        #expect(throws: UncertainValueError.self) {
            try uv.asMultiplicative
        }
    }

    @Test func conversionThrowsWhenMultiplicativeErrorWouldBeInvalid() {
        let uv = UncertainValue(10.0, absoluteError: .infinity)
        #expect(throws: UncertainValueError.self) {
            try uv.asMultiplicative
        }
    }

    // MARK: - Log-Space Initializer

    @Test func logSpaceInitializer() {
        let logAbs = UncertainValue(Darwin.log(2.0), absoluteError: Darwin.log(1.1))
        let muv = MultiplicativeUncertainValue.unchecked(logAbs: logAbs, signum: .positive)
        #expect(abs(muv.value - 2.0) < accuracy)
        #expect(abs(muv.multiplicativeError - 1.1) < accuracy)
        #expect(muv.signum == .positive)
    }

    @Test func logSpaceInitializerNegativeSign() {
        let logAbs = UncertainValue(Darwin.log(3.0), absoluteError: Darwin.log(1.2))
        let muv = MultiplicativeUncertainValue.unchecked(logAbs: logAbs, signum: .negative)
        #expect(abs(muv.value - (-3.0)) < accuracy)
        #expect(muv.signum == .negative)
    }

    // MARK: - Static exp Constructor

    @Test func expDefaultSignCreatesPositive() throws {
        let logAbs = UncertainValue(Darwin.log(4.0), absoluteError: Darwin.log(1.2))
        let muv = try MultiplicativeUncertainValue.exp(logAbs)
        #expect(abs(muv.value - 4.0) < accuracy)
        #expect(muv.signum == .positive)
    }

    @Test func expWithNegativeSignCreatesNegative() throws {
        let logAbs = UncertainValue(Darwin.log(4.0), absoluteError: Darwin.log(1.2))
        let muv = try MultiplicativeUncertainValue.exp(logAbs, withResultSign: .negative)
        #expect(abs(muv.value - (-4.0)) < accuracy)
        #expect(muv.signum == .negative)
    }

    @Test func expPreservesLogAbs() throws {
        let logAbs = UncertainValue(Darwin.log(5.0), absoluteError: Darwin.log(1.3))
        let muv = try MultiplicativeUncertainValue.exp(logAbs, withResultSign: .positive)
        #expect(abs(muv.logAbs.value - logAbs.value) < accuracy)
        #expect(abs(muv.logAbs.absoluteError - logAbs.absoluteError) < accuracy)
    }

    @Test func expWithNonFiniteLogAbsThrows() {
        let nonFiniteLogAbs = UncertainValue(.infinity, absoluteError: 0.1)
        #expect(throws: UncertainValueError.nonFinite) {
            try MultiplicativeUncertainValue.exp(nonFiniteLogAbs)
        }
    }

    // MARK: - Reciprocal

    @Test func reciprocalValue() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let reciprocal = try muv.reciprocal
        #expect(abs(reciprocal.value - 0.5) < accuracy)
    }

    @Test func reciprocalPreservesSign() throws {
        let positive = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let negative = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.1)
        #expect(try positive.reciprocal.signum == .positive)
        #expect(try negative.reciprocal.signum == .negative)
    }

    @Test func reciprocalLogAbsNegated() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let reciprocal = try muv.reciprocal
        #expect(abs(reciprocal.logAbs.value - (-muv.logAbs.value)) < accuracy)
        #expect(abs(reciprocal.logAbs.absoluteError - muv.logAbs.absoluteError) < accuracy)
    }

    @Test func reciprocalOfReciprocal() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.2)
        let doubleReciprocal = try muv.reciprocal.reciprocal
        #expect(abs(doubleReciprocal.value - muv.value) < accuracy)
        #expect(abs(doubleReciprocal.multiplicativeError - muv.multiplicativeError) < accuracy)
    }

    // MARK: - Negative

    @Test func negativeFlipsValue() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        let neg = muv.negative
        #expect(abs(neg.value - (-5.0)) < accuracy)
    }

    @Test func negativeFlipsSign() {
        let positive = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        let negative = MultiplicativeUncertainValue.unchecked(value: -5.0, multiplicativeError: 1.1)
        #expect(positive.negative.signum == .negative)
        #expect(negative.negative.signum == .positive)
    }

    @Test func negativePreservesLogAbs() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        let neg = muv.negative
        #expect(abs(neg.logAbs.value - muv.logAbs.value) < accuracy)
        #expect(abs(neg.logAbs.absoluteError - muv.logAbs.absoluteError) < accuracy)
    }

    @Test func doubleNegative() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        let doubleNeg = muv.negative.negative
        #expect(abs(doubleNeg.value - muv.value) < accuracy)
        #expect(doubleNeg.signum == muv.signum)
    }

    // MARK: - Absolute Value

    @Test func absValuePositive() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        let abs = muv.absolute
        #expect(Swift.abs(abs.value - 5.0) < accuracy)
        #expect(abs.signum == .positive)
    }

    @Test func absValueNegative() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -5.0, multiplicativeError: 1.1)
        let abs = muv.absolute
        #expect(Swift.abs(abs.value - 5.0) < accuracy)
        #expect(abs.signum == .positive)
    }

    @Test func absValuePreservesLogAbs() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -5.0, multiplicativeError: 1.1)
        let abs = muv.absolute
        #expect(Swift.abs(abs.logAbs.value - muv.logAbs.value) < accuracy)
        #expect(Swift.abs(abs.logAbs.absoluteError - muv.logAbs.absoluteError) < accuracy)
    }

    @Test func absValueIdempotent() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -5.0, multiplicativeError: 1.1)
        let abs1 = muv.absolute
        let abs2 = abs1.absolute
        #expect(Swift.abs(abs2.value - abs1.value) < accuracy)
        #expect(abs2.signum == abs1.signum)
    }

    // MARK: - Raised to Integer Power

    @Test func raisedToIntegerPowerPositive() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: 3)
        #expect(abs(result.value - 8.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func raisedToEvenPowerBecomesPositive() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: 2)
        #expect(abs(result.value - 4.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func raisedToOddPowerPreservesSign() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: 3)
        #expect(abs(result.value - (-8.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    @Test func raisedToZeroPower() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.2)
        let result = try muv.raised(to: 0)
        #expect(abs(result.value - 1.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func raisedToNegativeIntegerPower() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: -2)
        #expect(abs(result.value - 0.25) < accuracy)
    }

    @Test func raisedToIntegerPowerLogAbsPropagation() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: 3)
        #expect(abs(result.logAbs.value - 3 * muv.logAbs.value) < accuracy)
        #expect(abs(result.logAbs.absoluteError - 3 * muv.logAbs.absoluteError) < accuracy)
    }

    // MARK: - Raised to Real Power

    @Test func raisedToRealPowerPositive() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 4.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: 0.5)
        #expect(abs(result.value - 2.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func raisedToRealPowerNegativeThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -4.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.self) {
            try muv.raised(to: 0.5)
        }
    }

    @Test func raisedToRealPowerLogAbsPropagation() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 4.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: 2.5)
        #expect(abs(result.logAbs.value - 2.5 * muv.logAbs.value) < accuracy)
        #expect(abs(result.logAbs.absoluteError - 2.5 * muv.logAbs.absoluteError) < accuracy)
    }

    @Test func raisedToNegativeRealPower() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 4.0, multiplicativeError: 1.1)
        let result = try muv.raised(to: -0.5)
        #expect(abs(result.value - 0.5) < accuracy)
    }

    // MARK: - isNegative

    @Test func isNegativeTrue() {
        let muv = MultiplicativeUncertainValue.unchecked(value: -5.0, multiplicativeError: 1.1)
        #expect(muv.isNegative)
    }

    @Test func isNegativeFalse() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.1)
        #expect(!muv.isNegative)
    }

    // MARK: - Multiplication

    @Test func multiplyingTwoPositiveValues() {
        let a = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: 3.0, multiplicativeError: 1.2)
        let result = a.multiplying(b, using: .l2)
        #expect(abs(result.value - 6.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func multiplyingPositiveAndNegative() {
        let a = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: -3.0, multiplicativeError: 1.2)
        let result = a.multiplying(b, using: .l2)
        #expect(abs(result.value - (-6.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    @Test func multiplyingTwoNegatives() {
        let a = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: -3.0, multiplicativeError: 1.2)
        let result = a.multiplying(b, using: .l2)
        #expect(abs(result.value - 6.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func multiplyingErrorPropagation() {
        let a = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: 3.0, multiplicativeError: 1.1)
        let result = a.multiplying(b, using: .l2)
        let expectedLogError = sqrt(2.0) * Darwin.log(1.1)
        #expect(abs(result.logAbs.absoluteError - expectedLogError) < accuracy)
    }

    @Test func multiplyingWithL1Norm() {
        let a = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: 3.0, multiplicativeError: 1.2)
        let result = a.multiplying(b, using: .l1)
        let expectedLogError = Darwin.log(1.1) + Darwin.log(1.2)
        #expect(abs(result.logAbs.absoluteError - expectedLogError) < accuracy)
    }

    // MARK: - Division

    @Test func dividingTwoPositives() throws {
        let a = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.2)
        let result = try a.dividing(by: b, using: .l2)
        #expect(abs(result.value - 3.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func dividingNegativeByPositive() throws {
        let a = MultiplicativeUncertainValue.unchecked(value: -6.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.2)
        let result = try a.dividing(by: b, using: .l2)
        #expect(abs(result.value - (-3.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    @Test func dividingPositiveByNegative() throws {
        let a = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.2)
        let result = try a.dividing(by: b, using: .l2)
        #expect(abs(result.value - (-3.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    @Test func dividingTwoNegatives() throws {
        let a = MultiplicativeUncertainValue.unchecked(value: -6.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.2)
        let result = try a.dividing(by: b, using: .l2)
        #expect(abs(result.value - 3.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func dividingIsInverseOfMultiplying() throws {
        let a = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let b = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.05)
        let product = a.multiplying(b, using: .l2)
        let quotient = try product.dividing(by: b, using: .l2)
        #expect(abs(quotient.value - a.value) < accuracy)
    }

    // MARK: - Array Product

    @Test func arrayProductTwoElements() {
        let values = [
            MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: 3.0, multiplicativeError: 1.2)
        ]
        let result = values.product(using: .l2)
        #expect(abs(result.value - 6.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func arrayProductThreeElements() {
        let values = [
            MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: 3.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: 4.0, multiplicativeError: 1.1)
        ]
        let result = values.product(using: .l2)
        #expect(abs(result.value - 24.0) < accuracy)
    }

    @Test func arrayProductWithNegatives() {
        let values = [
            MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: -3.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: -4.0, multiplicativeError: 1.1)
        ]
        let result = values.product(using: .l2)
        #expect(abs(result.value - 24.0) < accuracy)
        #expect(result.signum == .positive)
    }

    @Test func arrayProductOddNegatives() {
        let values = [
            MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: -3.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: 4.0, multiplicativeError: 1.1)
        ]
        let result = values.product(using: .l2)
        #expect(abs(result.value - (-24.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    @Test func arrayProductSingleElement() {
        let values = [MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.2)]
        let result = values.product(using: .l2)
        #expect(abs(result.value - 5.0) < accuracy)
        #expect(abs(result.multiplicativeError - 1.2) < accuracy)
    }

    @Test func arrayProductEmptyArray() {
        let values: [MultiplicativeUncertainValue] = []
        let result = values.product(using: .l2)
        #expect(abs(result.value - 1.0) < accuracy)
        #expect(abs(result.multiplicativeError - 1.0) < accuracy)
    }

    @Test func arrayProductL1VsL2() {
        let values = [
            MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1),
            MultiplicativeUncertainValue.unchecked(value: 3.0, multiplicativeError: 1.2)
        ]
        let resultL1 = values.product(using: .l1)
        let resultL2 = values.product(using: .l2)
        #expect(resultL1.logAbs.absoluteError > resultL2.logAbs.absoluteError)
    }

    // MARK: - Signum Product

    @Test func signumProductAllPositive() {
        let signs: [Signum] = [.positive, .positive, .positive]
        #expect(signs.product() == .positive)
    }

    @Test func signumProductOneNegative() {
        let signs: [Signum] = [.positive, .negative, .positive]
        #expect(signs.product() == .negative)
    }

    @Test func signumProductTwoNegatives() {
        let signs: [Signum] = [.negative, .negative, .positive]
        #expect(signs.product() == .positive)
    }

    @Test func signumProductThreeNegatives() {
        let signs: [Signum] = [.negative, .negative, .negative]
        #expect(signs.product() == .negative)
    }

    @Test func signumProductEmpty() {
        let signs: [Signum] = []
        #expect(signs.product() == .positive)
    }

    @Test func signumProductSinglePositive() {
        let signs: [Signum] = [.positive]
        #expect(signs.product() == .positive)
    }

    @Test func signumProductSingleNegative() {
        let signs: [Signum] = [.negative]
        #expect(signs.product() == .negative)
    }

    @Test func signumProductWithZero() {
        let signs: [Signum] = [.positive, .zero, .negative]
        #expect(signs.product() == .zero)
    }

    // MARK: - Scaling by Constant

    @Test func scaledUpPositiveByPositive() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let scaled = try muv.scaledUp(by: 3.0)
        #expect(abs(scaled.value - 6.0) < accuracy)
        #expect(abs(scaled.multiplicativeError - 1.1) < accuracy)
        #expect(scaled.signum == .positive)
    }

    @Test func scaledUpPositiveByNegative() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let scaled = try muv.scaledUp(by: -3.0)
        #expect(abs(scaled.value - (-6.0)) < accuracy)
        #expect(abs(scaled.multiplicativeError - 1.1) < accuracy)
        #expect(scaled.signum == .negative)
    }

    @Test func scaledUpNegativeByPositive() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.1)
        let scaled = try muv.scaledUp(by: 3.0)
        #expect(abs(scaled.value - (-6.0)) < accuracy)
        #expect(scaled.signum == .negative)
    }

    @Test func scaledUpNegativeByNegative() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: -2.0, multiplicativeError: 1.1)
        let scaled = try muv.scaledUp(by: -3.0)
        #expect(abs(scaled.value - 6.0) < accuracy)
        #expect(scaled.signum == .positive)
    }

    @Test func scaledUpPreservesMultiplicativeError() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 5.0, multiplicativeError: 1.25)
        let scaled = try muv.scaledUp(by: 10.0)
        #expect(abs(scaled.multiplicativeError - muv.multiplicativeError) < accuracy)
    }

    @Test func scaledUpAbsoluteErrorScalesCorrectly() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let lambda = 3.0
        let scaled = try muv.scaledUp(by: lambda)
        let originalAbsError = Swift.abs(muv.value) * (muv.multiplicativeError - 1)
        let scaledAbsError = Swift.abs(scaled.value) * (scaled.multiplicativeError - 1)
        #expect(Swift.abs(scaledAbsError - Swift.abs(lambda) * originalAbsError) < accuracy)
    }

    @Test func scaledDownPositive() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let scaled = try muv.scaledDown(by: 2.0)
        #expect(abs(scaled.value - 3.0) < accuracy)
        #expect(abs(scaled.multiplicativeError - 1.1) < accuracy)
    }

    @Test func scaledDownByNegative() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let scaled = try muv.scaledDown(by: -2.0)
        #expect(abs(scaled.value - (-3.0)) < accuracy)
        #expect(scaled.signum == .negative)
    }

    // MARK: - Scaling Error Cases

    @Test func scaledUpByZeroThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.invalidScale) {
            try muv.scaledUp(by: 0.0)
        }
    }

    @Test func scaledUpByNonFiniteThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.invalidScale) {
            try muv.scaledUp(by: .infinity)
        }
    }

    @Test func scaledDownByZeroThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.self) {
            try muv.scaledDown(by: 0.0)
        }
    }

    // MARK: - Mixed Operators (Double * MUV, etc.)

    @Test func doubleTimesMUV() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try 3.0 * muv
        #expect(abs(result.value - 6.0) < accuracy)
        #expect(abs(result.multiplicativeError - 1.1) < accuracy)
    }

    @Test func muvTimesDouble() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try muv * 3.0
        #expect(abs(result.value - 6.0) < accuracy)
        #expect(abs(result.multiplicativeError - 1.1) < accuracy)
    }

    @Test func muvDividedByDouble() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let result = try muv / 2.0
        #expect(abs(result.value - 3.0) < accuracy)
        #expect(abs(result.multiplicativeError - 1.1) < accuracy)
    }

    @Test func doubleDividedByMUV() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try 6.0 / muv
        #expect(abs(result.value - 3.0) < accuracy)
        #expect(abs(result.multiplicativeError - 1.1) < accuracy)
    }

    @Test func negativeDoubleTimesMUV() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        let result = try -3.0 * muv
        #expect(abs(result.value - (-6.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    @Test func muvDividedByNegativeDouble() throws {
        let muv = MultiplicativeUncertainValue.unchecked(value: 6.0, multiplicativeError: 1.1)
        let result = try muv / -2.0
        #expect(abs(result.value - (-3.0)) < accuracy)
        #expect(result.signum == .negative)
    }

    // MARK: - Operator Error Cases

    @Test func muvTimesZeroThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.self) {
            try muv * 0.0
        }
    }

    @Test func zeroTimesMUVThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.self) {
            try 0.0 * muv
        }
    }

    @Test func muvDividedByZeroThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.self) {
            try muv / 0.0
        }
    }

    @Test func zeroDividedByMUVThrows() {
        let muv = MultiplicativeUncertainValue.unchecked(value: 2.0, multiplicativeError: 1.1)
        #expect(throws: UncertainValueError.self) {
            try 0.0 / muv
        }
    }
}
