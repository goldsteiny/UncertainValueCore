import Foundation
import Testing
import UncertainValueCore
import UncertainValueStatistics
import UncertainValueSupport

private enum GiniTestConstants {
    static let defaultAccuracy: Double = 1e-10
    static let numericalDiffAccuracy: Double = 1e-5
    static let perturbationEpsilon: Double = 1e-6
}

struct GiniCoefficientDoubleTests {
    @Test func knownValueOneTwoThree() throws {
        let values = [1.0, 2.0, 3.0]
        let result = try values.giniCoefficientL2()
        #expect(isClose(result, 2.0 / 9.0))
    }

    @Test func knownValueZeroZeroFive() throws {
        let values = [0.0, 0.0, 5.0]
        let result = try values.giniCoefficientL2()
        #expect(isClose(result, 2.0 / 3.0))
    }

    @Test func equalValuesAreZero() throws {
        let values = [4.0, 4.0, 4.0, 4.0]
        let result = try values.giniCoefficientL2()
        #expect(isClose(result, 0.0))
    }

    @Test func permutationInvariant() throws {
        let values = [1.0, 5.0, 2.0, 7.0, 3.0]
        let permuted = [7.0, 1.0, 3.0, 5.0, 2.0]
        let base = try values.giniCoefficientL2()
        let result = try permuted.giniCoefficientL2()
        #expect(isClose(base, result))
    }

    @Test func scaleInvariant() throws {
        let values = [0.1, 0.3, 1.4, 2.8]
        let scaled = values.map { $0 * 1000.0 }
        let base = try values.giniCoefficientL2()
        let result = try scaled.giniCoefficientL2()
        #expect(isClose(base, result))
    }

    @Test func allZeroThrows() {
        #expect(throws: UncertainValueError.self) {
            try [0.0, 0.0, 0.0].giniCoefficientL2()
        }
    }

    @Test func negativeInputThrows() {
        #expect(throws: UncertainValueError.self) {
            try [-1.0, 0.0, 2.0].giniCoefficientL2()
        }
    }

    @Test func nonFiniteThrows() {
        #expect(throws: UncertainValueError.self) {
            try [1.0, .infinity, 3.0].giniCoefficientL2()
        }
    }
}

struct GiniCoefficientUncertainValueTests {
    @Test func errorFreeInputsRemainErrorFree() throws {
        let values = [1.0, 2.0, 3.0].map(UncertainValue.errorFree)
        let result = try values.giniCoefficientL2()
        #expect(isClose(result.value, 2.0 / 9.0))
        #expect(isClose(result.absoluteError, 0.0))
    }

    @Test func uncertaintyPropagationMatchesNumericalDerivatives() throws {
        let baseValues = [1.0, 2.0, 4.0]
        let errors = [0.1, 0.2, 0.3]
        let values = zip(baseValues, errors).map { value, error in
            UncertainValue(value, absoluteError: error)
        }
        let result = try values.giniCoefficientL2()

        var expectedErrorSquared = 0.0
        for j in 0..<baseValues.count {
            var plus = baseValues
            plus[j] += GiniTestConstants.perturbationEpsilon
            let plusValue = try plus.giniCoefficientL2()

            var minus = baseValues
            minus[j] -= GiniTestConstants.perturbationEpsilon
            let minusValue = try minus.giniCoefficientL2()

            let partial = (plusValue - minusValue) / (2.0 * GiniTestConstants.perturbationEpsilon)
            expectedErrorSquared += partial * partial * errors[j] * errors[j]
        }

        let expectedError = sqrt(expectedErrorSquared)
        #expect(
            isClose(result.absoluteError, expectedError, accuracy: GiniTestConstants.numericalDiffAccuracy),
            "analytic=\(result.absoluteError), numerical=\(expectedError)"
        )
    }

    @Test func tiesArePermutationStable() throws {
        let valuesA = [
            UncertainValue(1.0, absoluteError: 0.1),
            UncertainValue(1.0, absoluteError: 0.2),
            UncertainValue(4.0, absoluteError: 0.3),
        ]
        let valuesB = [valuesA[1], valuesA[2], valuesA[0]]

        let resultA = try valuesA.giniCoefficientL2()
        let resultB = try valuesB.giniCoefficientL2()

        #expect(isClose(resultA.value, resultB.value))
        #expect(isClose(resultA.absoluteError, resultB.absoluteError))
    }
}

private func isClose(_ lhs: Double, _ rhs: Double, accuracy: Double = GiniTestConstants.defaultAccuracy) -> Bool {
    abs(lhs - rhs) <= accuracy
}
