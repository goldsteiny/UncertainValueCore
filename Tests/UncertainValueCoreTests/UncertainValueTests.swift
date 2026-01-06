//
//  UncertainValueTests.swift
//  UncertainValueCoreTests
//
//  Tests for UncertainValue arithmetic and array operations.
//  All tests use explicit norm strategies (no operators).
//

import Foundation
import Testing
@testable import UncertainValueCore

struct UncertainValueTests {
    // MARK: - Initialization Tests

    @Test func initWithAbsoluteError() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        #expect(x.value == 10.0)
        #expect(x.absoluteError == 0.5)
        #expect(x.relativeError == 0.05)
    }

    @Test func initWithRelativeError() {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        #expect(x.value == 10.0)
        #expect(x.absoluteError == 0.5)
        #expect(x.relativeError == 0.05)
    }

    @Test func initWithCombinedErrors() {
        let x = UncertainValue.withCombinedErrors(10.0, absoluteError: 0.3, relativeError: 0.02)
        #expect(x.value == 10.0)
        // total = 0.3 + 10.0 * 0.02 = 0.5
        #expect(x.absoluteError == 0.5)
        #expect(x.relativeError == 0.05)
    }

    @Test func negativeAbsoluteErrorIsAbsoluted() {
        let x = UncertainValue(10.0, absoluteError: -0.5)
        #expect(x.absoluteError == 0.5)
    }

    @Test func zeroValueWithErrorHasInfiniteRelativeError() {
        let x = UncertainValue(0.0, absoluteError: 0.5)
        #expect(x.relativeError == .infinity)
    }

    @Test func zeroValueWithZeroErrorHasZeroRelativeError() {
        let x = UncertainValue(0.0, absoluteError: 0.0)
        #expect(x.relativeError == 0.0)
    }

    @Test func variance() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        #expect(x.variance == 0.25)
    }
    
    @Test func absoluteValue() {
        let x = UncertainValue(-3.0, absoluteError: 0.2)
        #expect(x.absoluteValue == 3.0)
    }
    
    @Test func absoluteUncertainValue() {
        let x = UncertainValue(-3.0, absoluteError: 0.2)
        let result = x.absolute
        #expect(result.value == 3.0)
        #expect(result.absoluteError == 0.2)
    }

    // MARK: - Constants Tests

    @Test func constantZero() {
        let z = UncertainValue.zero
        #expect(z.value == 0.0)
        #expect(z.absoluteError == 0.0)
    }

    @Test func constantOne() {
        let o = UncertainValue.one
        #expect(o.value == 1.0)
        #expect(o.absoluteError == 0.0)
    }

    @Test func constantPi() {
        let p = UncertainValue.pi
        #expect(p.value == Double.pi)
        #expect(p.absoluteError == 0.0)
    }

    @Test func constantE() {
        let e = UncertainValue.e
        #expect(e.value == M_E)
        #expect(e.absoluteError == 0.0)
    }

    // MARK: - Array Helper Properties Tests

    @Test func arrayValues() {
        let arr = [
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.2),
            UncertainValue(3.0, absoluteError: 0.3)
        ]
        #expect(arr.values == [1.0, 2.0, 3.0])
    }

    @Test func arrayAbsoluteErrors() {
        let arr = [
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.2),
            UncertainValue(3.0, absoluteError: 0.3)
        ]
        #expect(arr.absoluteErrors == [0.1, 0.2, 0.3])
    }

    @Test func arrayRelativeErrors() {
        let arr = [
            UncertainValue(10.0, absoluteError: 1.0),  // 10%
            UncertainValue(20.0, absoluteError: 1.0)   // 5%
        ]
        #expect(arr.relativeErrors == [0.1, 0.05])
    }
    
    @Test func arrayAbsMaxByMagnitude() {
        let arr = [
            UncertainValue(-10.0, absoluteError: 0.1),
            UncertainValue(5.0, absoluteError: 0.2),
            UncertainValue(-3.0, absoluteError: 0.3)
        ]
        #expect(arr.absMax?.value == 10.0)
        #expect(arr.absMax?.absoluteError == 0.1)
    }

    @Test func arrayAbsMaxAllPositive() {
        let arr = [
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(4.0, absoluteError: 0.2),
            UncertainValue(3.0, absoluteError: 0.3)
        ]
        #expect(arr.absMax?.value == 4.0)
    }

    @Test func arrayAbsMaxAllNegative() {
        let arr = [
            UncertainValue(-1.0, absoluteError: 0.1),
            UncertainValue(-4.0, absoluteError: 0.2),
            UncertainValue(-3.0, absoluteError: 0.3)
        ]
        #expect(arr.absMax?.value == 4.0)
    }

    @Test func arrayAbsMaxLargeAndSmallValues() {
        let arr = [
            UncertainValue(1.0e-9, absoluteError: 0.1),
            UncertainValue(-1.0e6, absoluteError: 0.2),
            UncertainValue(2.0e3, absoluteError: 0.3)
        ]
        #expect(arr.absMax?.value == 1.0e6)
    }
    
    @Test func arrayAbsMaxTieBreaksByError() {
        let arr = [
            UncertainValue(-2.0, absoluteError: 0.1),
            UncertainValue(2.0, absoluteError: 0.4)
        ]
        #expect(arr.absMax?.absoluteError == 0.4)
        #expect(arr.absMax?.value == 2.0)
    }

    @Test func arrayAbsMaxEmptyReturnsNil() {
        let arr: [UncertainValue] = []
        #expect(arr.absMax == nil)
    }
    
    @Test func arrayMeanWithL2() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.mean(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 15.0)
        // error = sum_error / count = 0.5 / 2 = 0.25
        #expect(abs(result!.absoluteError - 0.25) < 0.0001)
    }

    @Test func arrayMeanMixedSigns() {
        let values = [
            UncertainValue(-10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.mean(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
        #expect(abs(result!.absoluteError - 0.25) < 0.0001)
    }

    @Test func arrayMeanLargeAndSmallValues() {
        let values = [
            UncertainValue(1.0e-6, absoluteError: 0.1),
            UncertainValue(1.0e6, absoluteError: 0.2)
        ]
        let result = values.mean(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 500000.0000005)
    }

    @Test func arrayMeanWithL1() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.mean(using: .l1)

        #expect(result != nil)
        #expect(result!.value == 15.0)
        // L1 sum error = 0.3 + 0.4 = 0.7, mean error = 0.7 / 2 = 0.35
        #expect(abs(result!.absoluteError - 0.35) < 0.0001)
    }

    @Test func arrayMeanSingleValue() {
        let values = [UncertainValue(5.0, absoluteError: 0.2)]
        let result = values.mean(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
        #expect(result!.absoluteError == 0.2)
    }
    
    @Test func arrayMeanEmptyReturnsNil() {
        let values: [UncertainValue] = []
        #expect(values.mean(using: .l2) == nil)
    }
    
    // MARK: - Double Array Helper Tests
    
    @Test func doubleArrayAbsMax() {
        let values = [-1.0, 2.5, -3.0]
        #expect(values.absMax == 3.0)
    }

    @Test func doubleArrayAbsMaxAllPositive() {
        let values = [1.0, 2.5, 3.0]
        #expect(values.absMax == 3.0)
    }

    @Test func doubleArrayAbsMaxAllNegative() {
        let values = [-1.0, -2.5, -3.0]
        #expect(values.absMax == 3.0)
    }

    @Test func doubleArrayAbsMaxTieReturnsPositive() {
        let values = [-2.0, 2.0]
        #expect(values.absMax == 2.0)
    }

    @Test func doubleArrayAbsMaxAllNegative2() {
        let values = [-1.0, -4.0, -2.0]
        #expect(values.absMax == 4.0)
    }
    
    @Test func doubleArrayAbsMaxEmpty() {
        let values: [Double] = []
        #expect(values.absMax == nil)
    }
    
    @Test func doubleArraySumAndProduct() {
        let values = [-2.0, 3.0, 0.5]
        #expect(values.sum == 1.5)
        #expect(values.product == -3.0)
    }

    @Test func doubleArraySumAndProductAllPositive() {
        let values = [1.0, 2.0, 3.0]
        #expect(values.sum == 6.0)
        #expect(values.product == 6.0)
    }

    @Test func doubleArraySumAndProductAllNegative() {
        let values = [-1.0, -2.0, -3.0]
        #expect(values.sum == -6.0)
        #expect(values.product == -6.0)
    }

    @Test func doubleArraySumLargeAndSmallValues() {
        let values = [1.0e-9, 1.0e9, -1.0e-9]
        #expect(values.sum == 1.0e9)
    }
    
    @Test func doubleArraySumProductEmpty() {
        let values: [Double] = []
        #expect(values.sum == 0.0)
        #expect(values.product == 1.0)
    }

    // MARK: - Arithmetic Tests (explicit norm)

    @Test func addition() {
        let x = UncertainValue(10.0, absoluteError: 0.3)
        let y = UncertainValue(5.0, absoluteError: 0.4)
        let result = x.adding(y, using: .l2)

        #expect(result.value == 15.0)
        // L2: sqrt(0.3^2 + 0.4^2) = sqrt(0.25) = 0.5
        #expect(abs(result.absoluteError - 0.5) < 0.0001)
    }

    @Test func subtraction() {
        let x = UncertainValue(10.0, absoluteError: 0.3)
        let y = UncertainValue(5.0, absoluteError: 0.4)
        let result = x.subtracting(y, using: .l2)

        #expect(result.value == 5.0)
        #expect(abs(result.absoluteError - 0.5) < 0.0001)
    }

    @Test func multiplication() {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        let y = UncertainValue.withRelativeError(5.0, 0.04)
        let result = x.multiplying(y, using: .l2)

        #expect(result.value == 50.0)
        // L2: sqrt(0.05^2 + 0.04^2) ≈ 0.0640
        #expect(abs(result.relativeError - 0.0640) < 0.001)
    }

    @Test func division() throws {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        let y = UncertainValue.withRelativeError(5.0, 0.04)
        let result = try x.dividing(by: y, using: .l2)

        #expect(result.value == 2.0)
        #expect(abs(result.relativeError - 0.0640) < 0.001)
    }

    @Test func divisionByZeroThrows() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        let zero = UncertainValue(0.0, absoluteError: 0.0)
        do {
            _ = try x.dividing(by: zero, using: .l2)
            #expect(false)
        } catch let error as UncertainValueError {
            #expect(error == .divisionByZero)
        } catch {
            #expect(false)
        }
    }

    @Test func power() {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        let result = x.raised(to: 2.0)

        #expect(result != nil)
        #expect(result!.value == 100.0)
        // relError = |p| * relError(x) = 2 * 0.05 = 0.10
        #expect(abs(result!.relativeError - 0.10) < 0.001)
    }

    @Test func powerOfNegativeReturnsNil() {
        let x = UncertainValue(-10.0, absoluteError: 0.5)
        #expect(x.raised(to: 2.0) == nil)
    }

    @Test func powerOfZeroNoErrorReturnsZero() {
        let x = UncertainValue.zero
        let result = x.raised(to: 2.0)

        #expect(x != nil)
        #expect(result!.value == 0.0)
        #expect(result!.absoluteError == 0.0)
    }

    @Test func powerOfZeroWithErrorReturnsNil() {
        let x = UncertainValue(0.0, absoluteError: 1.0)
        #expect(x.raised(to: 2.0) == nil)
    }

    // MARK: - Integer Power Tests

    @Test func integerPowerNegativeBaseEvenExponent() {
        let x = UncertainValue(-2.0, absoluteError: 0.1)  // 5% relative
        let result = x.raised(to: 2)

        #expect(result != nil)
        #expect(result!.value == 4.0)
        // relError = |n| * relError(x) = 2 * 0.05 = 0.10
        #expect(abs(result!.relativeError - 0.10) < 0.001)
    }

    @Test func integerPowerNegativeBaseOddExponent() {
        let x = UncertainValue(-2.0, absoluteError: 0.1)  // 5% relative
        let result = x.raised(to: 3)

        #expect(result != nil)
        #expect(result!.value == -8.0)
        // relError = |n| * relError(x) = 3 * 0.05 = 0.15
        #expect(abs(result!.relativeError - 0.15) < 0.001)
    }

    @Test func integerPowerZeroBaseZeroErrorPositiveExponent() {
        let x = UncertainValue(0.0, absoluteError: 0.0)
        let result = x.raised(to: 2)

        #expect(result != nil)
        #expect(result!.value == 0.0)
        #expect(result!.absoluteError == 0.0)
    }

    @Test func integerPowerZeroBaseNonZeroErrorReturnsNil() {
        let x = UncertainValue(0.0, absoluteError: 0.1)
        #expect(x.raised(to: 2) == nil)
    }

    @Test func negative() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        let neg = x.negative
        #expect(neg.value == -10.0)
        #expect(neg.absoluteError == 0.5)
    }

    @Test func reciprocal() throws {
        let x = UncertainValue.withRelativeError(4.0, 0.05)
        let rec = try x.reciprocal

        #expect(rec.value == 0.25)
        #expect(abs(rec.relativeError - 0.05) < 0.001)
    }

    @Test func reciprocalOfZeroThrows() {
        let zero = UncertainValue(0.0, absoluteError: 0.0)
        do {
            _ = try zero.reciprocal
            #expect(false)
        } catch let error as UncertainValueError {
            #expect(error == .divisionByZero)
        } catch {
            #expect(false)
        }
    }

    @Test func exponentiationOperator() {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        let result = x ** 2.0

        #expect(result != nil)
        #expect(result!.value == 100.0)
        #expect(abs(result!.relativeError - 0.10) < 0.001)
    }

    // MARK: - Constant Operations (no norm needed)

    @Test func addConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let sum = x.adding(2.0)
        #expect(sum.value == 12.0)
        #expect(sum.absoluteError == 0.5)
    }

    @Test func subtractConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let sub = x.subtracting(5.0)
        #expect(sub.value == 5.0)
        #expect(sub.absoluteError == 0.5)
    }

    @Test func multiplyByConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let prod = x.multiplying(by: 2.0)
        #expect(prod.value == 20.0)
        #expect(prod.absoluteError == 1.0)
    }

    @Test func divideByConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let div = x.dividing(by: 2.0)
        #expect(div != nil)
        #expect(div!.value == 5.0)
        #expect(div!.absoluteError == 0.25)
    }

    @Test func divideByConstantZeroReturnsNil() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        #expect(x.dividing(by: 0.0) == nil)
    }

    @Test func multiplyByNegativeConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let prod = x.multiplying(by: -2.0)
        #expect(prod.value == -20.0)
        #expect(prod.absoluteError == 1.0)  // abs() applied in init
    }

    @Test func divideByNegativeConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let div = x.dividing(by: -2.0)
        #expect(div != nil)
        #expect(div!.value == -5.0)
        #expect(div!.relativeError == 0.05)  // relative error preserved
    }

    // MARK: - Array Operations with Explicit Norm

    @Test func arraySumWithL1() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.sum(using: .l1)

        #expect(result.value == 30.0)
        // L1: |0.3| + |0.4| = 0.7
        #expect(abs(result.absoluteError - 0.7) < 0.0001)
    }

    @Test func arraySumWithL2() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.sum(using: .l2)

        #expect(result.value == 30.0)
        // L2: sqrt(0.3^2 + 0.4^2) = 0.5
        #expect(abs(result.absoluteError - 0.5) < 0.0001)
    }

    @Test func arraySumMixedSigns() {
        let values = [
            UncertainValue(-10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let result = values.sum(using: .l2)

        #expect(result.value == 10.0)
        #expect(abs(result.absoluteError - 0.5) < 0.0001)
    }

    @Test func arraySumLargeAndSmallValues() {
        let values = [
            UncertainValue(1.0e-9, absoluteError: 0.1),
            UncertainValue(1.0e9, absoluteError: 0.2)
        ]
        let result = values.sum(using: .l2)

        #expect(result.value == 1.0e9)
    }

    @Test func arraySumWithLp() {
        let values = [
            UncertainValue(10.0, absoluteError: 3.0),
            UncertainValue(20.0, absoluteError: 4.0)
        ]
        let result = values.sum(using: .lp(p: 3.0))

        #expect(result.value == 30.0)
        // Lp with p=3: (3^3 + 4^3)^(1/3) = (27 + 64)^(1/3) ≈ 4.498
        #expect(abs(result.absoluteError - 4.498) < 0.001)
    }

    @Test func arrayProductWithL1() {
        let values = [
            UncertainValue(2.0, absoluteError: 0.2),  // 10% relative
            UncertainValue(3.0, absoluteError: 0.3)   // 10% relative
        ]
        let result = values.product(using: .l1)

        #expect(result.value == 6.0)
        // L1: 0.1 + 0.1 = 0.2 relative -> 1.2 absolute
        #expect(abs(result.absoluteError - 1.2) < 0.0001)
    }

    @Test func arrayProductWithL2() {
        let values = [
            UncertainValue(2.0, absoluteError: 0.2),  // 10% relative
            UncertainValue(3.0, absoluteError: 0.3)   // 10% relative
        ]
        let result = values.product(using: .l2)

        #expect(result.value == 6.0)
        // L2: sqrt(0.1^2 + 0.1^2) ≈ 0.1414 relative -> 0.849 absolute
        #expect(abs(result.absoluteError - 0.849) < 0.001)
    }

    @Test func arrayProductMixedSigns() {
        let values = [
            UncertainValue(-2.0, absoluteError: 0.2),  // 10% relative
            UncertainValue(3.0, absoluteError: 0.3)    // 10% relative
        ]
        let result = values.product(using: .l2)

        #expect(result.value == -6.0)
        #expect(abs(result.relativeError - 0.1414) < 0.001)
    }

    @Test func l1GivesLargerErrorThanL2() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(20.0, absoluteError: 0.4)
        ]
        let sumL1 = values.sum(using: .l1)
        let sumL2 = values.sum(using: .l2)

        #expect(sumL1.absoluteError > sumL2.absoluteError)
    }

    @Test func emptyArraySum() {
        let values: [UncertainValue] = []
        let result = values.sum(using: .l2)
        #expect(result.value == 0.0)
        #expect(result.absoluteError == 0.0)
    }

    @Test func emptyArrayProduct() {
        let values: [UncertainValue] = []
        let result = values.product(using: .l2)
        #expect(result.value == 1.0)  // identity for multiplication
        #expect(result.absoluteError == 0.0)
    }

    // MARK: - Norm2 Tests

    @Test func norm2Basic() {
        // Classic 3-4-5 triangle
        let values = [
            UncertainValue(3.0, absoluteError: 0.1),
            UncertainValue(4.0, absoluteError: 0.1)
        ]
        let result = values.norm2(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
    }

    @Test func norm2ErrorPropagation() {
        // x = 3 ± 0.1, y = 4 ± 0.1
        // x^2 = 9, relError = 2 * 0.1/3 = 0.0667, absError = 0.6
        // y^2 = 16, relError = 2 * 0.1/4 = 0.05, absError = 0.8
        // sum = 25, absError(L2) = sqrt(0.6^2 + 0.8^2) = 1.0
        // sqrt(25) = 5, relError = 0.5 * (1.0/25) = 0.02, absError = 0.1
        let values = [
            UncertainValue(3.0, absoluteError: 0.1),
            UncertainValue(4.0, absoluteError: 0.1)
        ]
        let result = values.norm2(using: .l2)!

        #expect(result.value == 5.0)
        #expect(abs(result.absoluteError - 0.1) < 0.0001)
    }

    @Test func norm2SingleElement() {
        let values = [UncertainValue(5.0, absoluteError: 0.2)]
        let result = values.norm2(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
        // x^2 = 25, relError = 2 * 0.04 = 0.08, absError = 2.0
        // sqrt: relError = 0.5 * 0.08 = 0.04, absError = 0.2
        #expect(abs(result!.absoluteError - 0.2) < 0.0001)
    }

    @Test func norm2EmptyArray() {
        let values: [UncertainValue] = []
        let result = values.norm2(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 0.0)
        #expect(result!.absoluteError == 0.0)
    }

    @Test func norm2WithNegativeValues() {
        // Negative values should work (squaring makes them positive)
        let values = [
            UncertainValue(-3.0, absoluteError: 0.1),
            UncertainValue(4.0, absoluteError: 0.1)
        ]
        let result = values.norm2(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
    }

    @Test func norm2AllNegativeValues() {
        // All-negative array: norm should still be positive
        let values = [
            UncertainValue(-3.0, absoluteError: 0.1),
            UncertainValue(-4.0, absoluteError: 0.1)
        ]
        let result = values.norm2(using: .l2)

        #expect(result != nil)
        #expect(result!.value == 5.0)
        #expect(result!.absoluteError > 0)
    }

    @Test func norm2MixedMagnitudes() {
        let values = [
            UncertainValue(1.0e-6, absoluteError: 0.1),
            UncertainValue(1.0e6, absoluteError: 0.1)
        ]
        let result = values.norm2(using: .l2)

        #expect(result != nil)
        #expect(abs(result!.value - 1.0e6) < 1.0)
    }

    // MARK: - Max/Min Tests

    @Test func maxReturnsLargestValue() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.1),
            UncertainValue(30.0, absoluteError: 0.2),
            UncertainValue(20.0, absoluteError: 0.3)
        ]
        let result = values.max

        #expect(result != nil)
        #expect(result!.value == 30.0)
        #expect(result!.absoluteError == 0.2)
    }

    @Test func maxEmptyReturnsNil() {
        let values: [UncertainValue] = []
        #expect(values.max == nil)
    }

    @Test func maxAllNegativeValues() {
        let values = [
            UncertainValue(-10.0, absoluteError: 0.1),
            UncertainValue(-30.0, absoluteError: 0.2),
            UncertainValue(-20.0, absoluteError: 0.3)
        ]
        let result = values.max

        #expect(result != nil)
        #expect(result!.value == -10.0)
    }

    @Test func maxTieBreaksWithLargerError() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.1),
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(10.0, absoluteError: 0.2)
        ]
        let result = values.max

        #expect(result != nil)
        #expect(result!.value == 10.0)
        #expect(result!.absoluteError == 0.3)
    }

    @Test func minReturnsSmallestValue() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.1),
            UncertainValue(30.0, absoluteError: 0.2),
            UncertainValue(20.0, absoluteError: 0.3)
        ]
        let result = values.min

        #expect(result != nil)
        #expect(result!.value == 10.0)
        #expect(result!.absoluteError == 0.1)
    }

    @Test func minEmptyReturnsNil() {
        let values: [UncertainValue] = []
        #expect(values.min == nil)
    }

    @Test func minMixedSigns() {
        let values = [
            UncertainValue(-10.0, absoluteError: 0.1),
            UncertainValue(5.0, absoluteError: 0.2),
            UncertainValue(-3.0, absoluteError: 0.3)
        ]
        let result = values.min

        #expect(result != nil)
        #expect(result!.value == -10.0)
    }

    @Test func minAllPositiveValues() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.1),
            UncertainValue(30.0, absoluteError: 0.2),
            UncertainValue(20.0, absoluteError: 0.3)
        ]
        let result = values.min

        #expect(result != nil)
        #expect(result!.value == 10.0)
    }

    @Test func minTieBreaksWithLargerError() {
        let values = [
            UncertainValue(10.0, absoluteError: 0.1),
            UncertainValue(10.0, absoluteError: 0.3),
            UncertainValue(10.0, absoluteError: 0.2)
        ]
        let result = values.min

        #expect(result != nil)
        #expect(result!.value == 10.0)
        #expect(result!.absoluteError == 0.3)
    }
}
