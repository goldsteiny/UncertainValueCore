//
//  OperatorTests.swift
//  UncertainValueConvenienceTests
//
//  Tests for convenience operators (L2 norm).
//

import Testing
@testable import UncertainValueCore
@testable import UncertainValueConvenience

struct OperatorTests {
    // MARK: - Binary Operators

    @Test func addition() {
        let x = UncertainValue(10.0, absoluteError: 0.3)
        let y = UncertainValue(5.0, absoluteError: 0.4)
        let result = x + y

        #expect(result.value == 15.0)
        // L2: sqrt(0.3^2 + 0.4^2) = 0.5
        #expect(abs(result.absoluteError - 0.5) < 0.0001)
    }

    @Test func subtraction() {
        let x = UncertainValue(10.0, absoluteError: 0.3)
        let y = UncertainValue(5.0, absoluteError: 0.4)
        let result = x - y

        #expect(result.value == 5.0)
        #expect(abs(result.absoluteError - 0.5) < 0.0001)
    }

    @Test func multiplication() {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        let y = UncertainValue.withRelativeError(5.0, 0.04)
        let result = x * y

        #expect(result.value == 50.0)
        // L2: sqrt(0.05^2 + 0.04^2) ≈ 0.0640
        #expect(abs(result.relativeError - 0.0640) < 0.001)
    }

    @Test func division() {
        let x = UncertainValue.withRelativeError(10.0, 0.05)
        let y = UncertainValue.withRelativeError(5.0, 0.04)
        let result = x / y

        #expect(result != nil)
        #expect(result!.value == 2.0)
        #expect(abs(result!.relativeError - 0.0640) < 0.001)
    }

    @Test func divisionByZeroReturnsNil() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        let zero = UncertainValue(0.0, absoluteError: 0.0)
        #expect(x / zero == nil)
    }

    // MARK: - Mixed Operators (Double, UncertainValue)

    @Test func addConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let sum1 = 2.0 + x
        #expect(sum1.value == 12.0)
        #expect(sum1.absoluteError == 0.5)

        let sum2 = x + 2.0
        #expect(sum2.value == 12.0)
        #expect(sum2.absoluteError == 0.5)
    }

    @Test func subtractConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let sub1 = 20.0 - x
        #expect(sub1.value == 10.0)
        #expect(sub1.absoluteError == 0.5)

        let sub2 = x - 5.0
        #expect(sub2.value == 5.0)
        #expect(sub2.absoluteError == 0.5)
    }
    
    @Test func multiplyByConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        
        let prod1 = 2.0 * x
        #expect(prod1.value == 20.0)
        #expect(prod1.absoluteError == 1.0)
        
        let prod2 = x * 2.0
        #expect(prod2.value == 20.0)
        #expect(prod2.absoluteError == 1.0)
    }
    
    @Test func multiplyZeroByConstant() {
        let x = UncertainValue(0.0, absoluteError: 0.5)
        
        let prod1 = 2.0 * x
        #expect(prod1.value == 0.0)
        #expect(prod1.absoluteError == 1.0)
        
        let prod2 = x * 2.0
        #expect(prod2.value == 0.0)
        #expect(prod2.absoluteError == 1.0)
    }

    @Test func divideByConstant() {
        let x = UncertainValue(10.0, absoluteError: 0.5)

        let div1 = 20.0 / x
        #expect(div1 != nil)
        #expect(div1!.value == 2.0)

        let div2 = x / 2.0
        #expect(div2 != nil)
        #expect(div2!.value == 5.0)
    }

    @Test func divideByConstantZeroReturnsNil() {
        let x = UncertainValue(10.0, absoluteError: 0.5)
        #expect(x / 0.0 == nil)
    }

    // MARK: - Verify Operators Use L2

    @Test func operatorsUseL2Norm() {
        let x = UncertainValue(10.0, absoluteError: 0.3)
        let y = UncertainValue(20.0, absoluteError: 0.4)

        // Using operator
        let operatorSum = x + y

        // Using explicit L2
        let explicitSum = x.adding(y, using: .l2)

        #expect(operatorSum.value == explicitSum.value)
        #expect(abs(operatorSum.absoluteError - explicitSum.absoluteError) < 1e-10)
    }
}
