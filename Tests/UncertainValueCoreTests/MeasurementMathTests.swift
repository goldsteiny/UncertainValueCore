//
//  UncertainValueMathTests.swift
//  UncertainValueCoreTests
//
//  Tests for UncertainValueMath functions with explicit norm strategies.
//

import Testing
@testable import UncertainValueCore

struct UncertainValueMathTests {
    // MARK: - Log Tests

    @Test func logPositiveValue() {
        let x = UncertainValue(10.0, absoluteError: 0.5)  // 5% relative error
        let result = UncertainValueMath.log(x)

        #expect(result != nil)
        #expect(abs(result!.value - 2.3026) < 0.001)  // ln(10)
        // delta(ln(x)) = relError(x) = 0.05
        #expect(abs(result!.absoluteError - 0.05) < 0.001)
    }

    @Test func logNegativeReturnsNil() {
        let x = UncertainValue(-10.0, absoluteError: 0.5)
        #expect(UncertainValueMath.log(x) == nil)
    }

    @Test func logZeroReturnsNil() {
        let x = UncertainValue(0.0, absoluteError: 0.0)
        #expect(UncertainValueMath.log(x) == nil)
    }

    @Test func logArray() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.5),
            UncertainValue(100.0, absoluteError: 5.0)
        ]
        let result = UncertainValueMath.log(values)

        #expect(result != nil)
        #expect(result!.count == 2)
        #expect(abs(result![0].value - 2.3026) < 0.001)  // ln(10)
        #expect(abs(result![1].value - 4.6052) < 0.001)  // ln(100)
    }

    @Test func logArrayWithNegativeReturnsNil() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.5),
            UncertainValue(-5.0, absoluteError: 0.5)
        ]
        #expect(UncertainValueMath.log(values) == nil)
    }

    // MARK: - Exp Tests

    @Test func expValue() {
        let x = UncertainValue(1.0, absoluteError: 0.1)
        let result = UncertainValueMath.exp(x)

        #expect(abs(result.value - 2.7183) < 0.001)  // e^1
        // relError(e^x) = absoluteError(x) = 0.1
        #expect(abs(result.relativeError - 0.1) < 0.001)
    }

    @Test func expZero() {
        let x = UncertainValue(0.0, absoluteError: 0.1)
        let result = UncertainValueMath.exp(x)
        #expect(abs(result.value - 1.0) < 0.0001)
    }

    @Test func expArray() {
        let values = [
            UncertainValue(0.0, absoluteError: 0.1),
            UncertainValue(1.0, absoluteError: 0.1)
        ]
        let result = UncertainValueMath.exp(values)

        #expect(result.count == 2)
        #expect(abs(result[0].value - 1.0) < 0.0001)    // e^0
        #expect(abs(result[1].value - 2.7183) < 0.001)  // e^1
    }

    // MARK: - Trig Tests

    @Test func sinValue() {
        let x = UncertainValue(0.0, absoluteError: 0.1)
        let result = UncertainValueMath.sin(x)

        #expect(abs(result.value - 0.0) < 0.0001)
        // delta(sin(0)) = |cos(0)| * 0.1 = 1.0 * 0.1 = 0.1
        #expect(abs(result.absoluteError - 0.1) < 0.0001)
    }

    @Test func cosValue() {
        let x = UncertainValue(0.0, absoluteError: 0.1)
        let result = UncertainValueMath.cos(x)

        #expect(abs(result.value - 1.0) < 0.0001)
        // delta(cos(0)) = |sin(0)| * 0.1 = 0.0 * 0.1 = 0.0
        #expect(abs(result.absoluteError - 0.0) < 0.0001)
    }

    @Test func sinAtPiOver2() {
        let x = UncertainValue(.pi / 2, absoluteError: 0.1)
        let result = UncertainValueMath.sin(x)

        #expect(abs(result.value - 1.0) < 0.0001)
        // delta(sin(pi/2)) = |cos(pi/2)| * 0.1 ≈ 0
        #expect(result.absoluteError < 0.001)
    }

    // MARK: - Reciprocal

    @Test func reciprocalValue() {
        let x = UncertainValue.withRelativeError(4.0, 0.05)
        let result = UncertainValueMath.reciprocal(x)

        #expect(result != nil)
        #expect(result!.value == 0.25)
        #expect(abs(result!.relativeError - 0.05) < 0.001)
    }

    @Test func reciprocalZeroReturnsNil() {
        let x = UncertainValue(0.0, absoluteError: 0.0)
        #expect(UncertainValueMath.reciprocal(x) == nil)
    }

    // MARK: - Polynomial

    @Test func polynomialConstant() {
        let coeffs = [UncertainValue(5.0, absoluteError: 0.1)]
        let x = UncertainValue(3.0, absoluteError: 0.2)
        let result = UncertainValueMath.polynomial(coeffs, x, using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
        #expect(abs(result!.absoluteError - 0.1) < 0.0001)
    }

    @Test func polynomialLinear() {
        // P(x) = 2 + 3x at x=4: 2 + 12 = 14
        let coeffs = [
            UncertainValue(2.0, absoluteError: 0.1),
            UncertainValue(3.0, absoluteError: 0.1)
        ]
        let x = UncertainValue(4.0, absoluteError: 0.2)
        let result = UncertainValueMath.polynomial(coeffs, x, using: .l2)

        #expect(result != nil)
        #expect(abs(result!.value - 14.0) < 0.0001)
    }

    @Test func polynomialEmptyReturnsNil() {
        let coeffs: [UncertainValue] = []
        let x = UncertainValue(3.0, absoluteError: 0.2)
        #expect(UncertainValueMath.polynomial(coeffs, x, using: .l2) == nil)
    }

    @Test func polynomialWithNegativeX() {
        // P(x) = 1 + 2x + 3x^2 at x = -2: 1 + 2(-2) + 3(4) = 1 - 4 + 12 = 9
        let coeffs = [
            UncertainValue(1.0, absoluteError: 0.0),
            UncertainValue(2.0, absoluteError: 0.0),
            UncertainValue(3.0, absoluteError: 0.0)
        ]
        let x = UncertainValue(-2.0, absoluteError: 0.0)
        let result = UncertainValueMath.polynomial(coeffs, x, using: .l2)

        #expect(result != nil)
        #expect(abs(result!.value - 9.0) < 0.0001)
    }

    @Test func polynomialWithZeroX() {
        // P(x) = 5 + 2x + 3x^2 at x = 0: should return a0 = 5
        let coeffs = [
            UncertainValue(5.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.1),
            UncertainValue(3.0, absoluteError: 0.1)
        ]
        let x = UncertainValue(0.0, absoluteError: 0.0)
        let result = UncertainValueMath.polynomial(coeffs, x, using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
        #expect(abs(result!.absoluteError - 0.1) < 0.0001)
    }

    // MARK: - Normalization

    @Test func normalizeValue() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        let denom = UncertainValue(2.0, absoluteError: 0.1)
        let result = UncertainValueMath.normalize([x], by: denom, using: .l2)

        #expect(result != nil)
        #expect(result!.count == 1)
        #expect(result![0].value == 5.0)
    }

    @Test func normalizeByFirst() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.5),
            UncertainValue(20.0, absoluteError: 1.0),
            UncertainValue(30.0, absoluteError: 1.5)
        ]
        let result = UncertainValueMath.normalizeByFirst(values, using: .l2)

        #expect(result != nil)
        #expect(result!.count == 3)
        #expect(result![0].value == 1.0)
        #expect(result![0].absoluteError == 0.0)
        #expect(result![1].value == 2.0)
        #expect(result![2].value == 3.0)
    }

    @Test func normalizeByFirstEmptyReturnsNil() {
        let values: [UncertainValue] = []
        #expect(UncertainValueMath.normalizeByFirst(values, using: .l2) == nil)
    }

    // MARK: - Average Step Width

    @Test func averageStepWidth() {
        let values = [
            UncertainValue(0.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.1),
            UncertainValue(4.0, absoluteError: 0.1),
            UncertainValue(6.0, absoluteError: 0.1),
            UncertainValue(8.0, absoluteError: 0.1)
        ]
        let result = UncertainValueMath.averageStepWidth(values, using: .l2)

        #expect(result != nil)
        #expect(result!.value == 2.0)  // (8 - 0) / 4
    }

    @Test func averageStepWidthSingleValueReturnsNil() {
        let values = [UncertainValue(5.0, absoluteError: 0.1)]
        #expect(UncertainValueMath.averageStepWidth(values, using: .l2) == nil)
    }

    // MARK: - Sigmoid (requires norm)

    @Test func sigmoidAtMidpoint() {
        let x = UncertainValue(0.0, absoluteError: 0.1)
        let x0 = UncertainValue(0.0, absoluteError: 0.1)
        let k = UncertainValue(1.0, absoluteError: 0.1)

        let result = UncertainValueMath.sigmoid(x, x0, k, using: .l2)

        // At midpoint (x = x0), sigmoid = 0.5
        #expect(abs(result.value - 0.5) < 0.0001)
    }

    @Test func sigmoidFarFromMidpoint() {
        let x = UncertainValue(10.0, absoluteError: 0.1)
        let x0 = UncertainValue(0.0, absoluteError: 0.1)
        let k = UncertainValue(1.0, absoluteError: 0.1)

        let result = UncertainValueMath.sigmoid(x, x0, k, using: .l2)

        // Far above midpoint, sigmoid approaches 1
        #expect(result.value > 0.999)
    }

    // MARK: - Lorentz Factor (requires norm)

    @Test func lorentzFactorValid() {
        let x = UncertainValue(0.6, absoluteError: 0.01)  // v = 0.6c
        let y = UncertainValue(1.0, absoluteError: 0.01)  // c = 1

        let result = UncertainValueMath.lorentzFactor(x, y, using: .l2)

        #expect(result != nil)
        // gamma = 1/sqrt(1 - 0.36) = 1/sqrt(0.64) = 1/0.8 = 1.25
        #expect(abs(result!.value - 1.25) < 0.001)
    }

    @Test func lorentzFactorAtLimitReturnsNil() {
        let x = UncertainValue(1.0, absoluteError: 0.01)  // v = c
        let y = UncertainValue(1.0, absoluteError: 0.01)

        #expect(UncertainValueMath.lorentzFactor(x, y, using: .l2) == nil)
    }

    @Test func lorentzFactorSuperluminalReturnsNil() {
        let x = UncertainValue(1.5, absoluteError: 0.01)  // v > c
        let y = UncertainValue(1.0, absoluteError: 0.01)

        #expect(UncertainValueMath.lorentzFactor(x, y, using: .l2) == nil)
    }

    @Test func lorentzFactorZeroDenominatorReturnsNil() {
        let x = UncertainValue(0.6, absoluteError: 0.01)
        let y = UncertainValue(0.0, absoluteError: 0.01)

        #expect(UncertainValueMath.lorentzFactor(x, y, using: .l2) == nil)
    }
}
