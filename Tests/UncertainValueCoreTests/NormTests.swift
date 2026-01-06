//
//  NormTests.swift
//  UncertainValueCoreTests
//
//  Tests for norm functions and NormStrategy.
//

import Testing
@testable import UncertainValueCore
import UncertainValueCoreAlgebra
import Foundation

struct NormTests {
    // MARK: - L1 Norm Tests

    @Test func norm1EmptyArray() {
        let result = norm1([])
        #expect(result == 0.0)
    }

    @Test func norm1SingleElement() {
        let result = norm1([3.0])
        #expect(result == 3.0)
    }

    @Test func norm1MultipleElements() {
        // |3| + |4| = 7
        let result = norm1([3.0, 4.0])
        #expect(abs(result - 7.0) < 0.0001)
    }

    @Test func norm1NegativeValues() {
        // |-3| + |4| = 7
        let result = norm1([-3.0, 4.0])
        #expect(abs(result - 7.0) < 0.0001)
    }

    @Test func norm1AllZeros() {
        let result = norm1([0.0, 0.0, 0.0])
        #expect(result == 0.0)
    }

    @Test func norm1ThreeElements() {
        // |1| + |-2| + |3| = 6
        let result = norm1([1.0, -2.0, 3.0])
        #expect(abs(result - 6.0) < 0.0001)
    }

    // MARK: - L2 Norm Tests

    @Test func norm2EmptyArray() {
        let result = norm2([])
        #expect(result == 0.0)
    }

    @Test func norm2SingleElement() {
        let result = norm2([3.0])
        #expect(result == 3.0)
    }

    @Test func norm2MultipleElements() {
        // sqrt(3^2 + 4^2) = sqrt(9 + 16) = sqrt(25) = 5
        let result = norm2([3.0, 4.0])
        #expect(abs(result - 5.0) < 0.0001)
    }

    @Test func norm2NegativeValues() {
        // sqrt((-3)^2 + 4^2) = 5
        let result = norm2([-3.0, 4.0])
        #expect(abs(result - 5.0) < 0.0001)
    }

    @Test func norm2AllZeros() {
        let result = norm2([0.0, 0.0, 0.0])
        #expect(result == 0.0)
    }

    @Test func norm2LargeValues() {
        // Test numerical stability with large values
        let result = norm2([1e100, 1e100])
        let expected = 1e100 * sqrt(2.0)
        #expect(abs(result - expected) / expected < 0.0001)
    }

    @Test func norm2SmallValues() {
        // Test numerical stability with small values
        let result = norm2([1e-100, 1e-100])
        let expected = 1e-100 * sqrt(2.0)
        #expect(abs(result - expected) / expected < 0.0001)
    }

    // MARK: - Lp Norm Tests

    @Test func normpWithP3() {
        // (3^3 + 4^3)^(1/3) = (27 + 64)^(1/3) = 91^(1/3) ≈ 4.498
        let result = normp([3.0, 4.0], p: 3.0)
        #expect(abs(result - 4.498) < 0.001)
    }

    @Test func normpWithP3NegativeValues() {
        // (|-3|^3 + |4|^3)^(1/3) ≈ 4.498
        let result = normp([-3.0, 4.0], p: 3.0)
        #expect(abs(result - 4.498) < 0.001)
    }

    @Test func normpConvergesToNorm1WhenP1() {
        let xs = [3.0, 4.0, 5.0]
        let resultP1 = normp(xs, p: 1.0)
        let resultNorm1 = norm1(xs)
        #expect(abs(resultP1 - resultNorm1) < 0.0001)
    }

    @Test func normpConvergesToNorm2WhenP2() {
        let xs = [3.0, 4.0]
        let resultP2 = normp(xs, p: 2.0)
        let resultNorm2 = norm2(xs)
        #expect(abs(resultP2 - resultNorm2) < 0.0001)
    }

    @Test func normpNumericalStability() {
        // Test with large values
        let result = normp([1e100, 1e100], p: 3.0)
        let expected = 1e100 * pow(2.0, 1.0/3.0)
        #expect(abs(result - expected) / expected < 0.0001)
    }

    // MARK: - NormStrategy Tests

    @Test func normStrategyL1() {
        let xs = [3.0, 4.0]
        let result = norm(xs, using: .l1)
        #expect(abs(result - 7.0) < 0.0001)
    }

    @Test func normStrategyL2() {
        let xs = [3.0, 4.0]
        let result = norm(xs, using: .l2)
        #expect(abs(result - 5.0) < 0.0001)
    }

    @Test func normStrategyLp() {
        let xs = [3.0, 4.0]
        let result = norm(xs, using: .lp(p: 3.0))
        #expect(abs(result - 4.498) < 0.001)
    }

    @Test func normStrategyHashable() {
        // Verify NormStrategy is Hashable for use in dictionaries/sets
        var set: Set<NormStrategy> = []
        set.insert(.l1)
        set.insert(.l2)
        set.insert(.lp(p: 3.0))
        set.insert(.lp(p: 3.0))  // duplicate
        #expect(set.count == 3)
    }
}
