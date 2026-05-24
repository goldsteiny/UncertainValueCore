import Foundation
import Testing
import UncertainValueCore
import UncertainValueStatistics
import UncertainValueSupport

private enum TestConstants {
    static let defaultAccuracy: Double = 1e-10
    static let numericalDiffAccuracy: Double = 1e-5
    static let perturbationEpsilon: Double = 1e-6
}

struct ZTransformDoubleTests {
    // MARK: - Value Correctness

    @Test func simpleSequence() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        let z = try values.zTransformL2()

        let sigma = Darwin.sqrt(2.5)
        let expected = values.map { ($0 - 3.0) / sigma }

        #expect(z.count == 5)
        for (actual, exp) in zip(z, expected) {
            #expect(isClose(actual, exp))
        }
    }

    @Test func minimumN2() throws {
        let values = [0.0, 10.0]
        let z = try values.zTransformL2()

        let invSqrt2 = 1.0 / Darwin.sqrt(2.0)
        #expect(z.count == 2)
        #expect(isClose(z[0], -invSqrt2))
        #expect(isClose(z[1], invSqrt2))
    }

    @Test func symmetricValues() throws {
        let values = [-3.0, -1.0, 1.0, 3.0]
        let z = try values.zTransformL2()

        #expect(z.count == 4)
        #expect(isClose(z[0], -z[3]))
        #expect(isClose(z[1], -z[2]))
    }

    // MARK: - Statistical Invariants

    @Test func sumOfZScoresIsZero() throws {
        let values = [2.7, 8.1, 3.5, 11.0, 6.3, 1.9, 4.4]
        let z = try values.zTransformL2()
        #expect(isClose(z.reduce(0, +), 0.0))
    }

    @Test func sampleStdDevOfZScoresIsOne() throws {
        let values = [2.7, 8.1, 3.5, 11.0, 6.3, 1.9, 4.4]
        let z = try values.zTransformL2()

        let zMean = z.reduce(0, +) / Double(z.count)
        let variance = z.map { ($0 - zMean) * ($0 - zMean) }.reduce(0, +) / Double(z.count - 1)
        #expect(isClose(Darwin.sqrt(variance), 1.0))
    }

    @Test func translationInvariance() throws {
        let values = [1.0, 3.0, 5.0, 7.0, 9.0]
        let shifted = values.map { $0 + 42.0 }

        let z1 = try values.zTransformL2()
        let z2 = try shifted.zTransformL2()

        for (a, b) in zip(z1, z2) {
            #expect(isClose(a, b))
        }
    }

    @Test func scaleInvariance() throws {
        let values = [1.0, 3.0, 5.0, 7.0, 9.0]
        let scaled = values.map { $0 * 1000.0 }

        let z1 = try values.zTransformL2()
        let z2 = try scaled.zTransformL2()

        for (a, b) in zip(z1, z2) {
            #expect(isClose(a, b))
        }
    }

    // MARK: - Edge Cases

    @Test func emptyArrayThrows() {
        #expect(throws: UncertainValueError.self) {
            try [Double]().zTransformL2()
        }
    }

    @Test func singleElementThrows() {
        #expect(throws: UncertainValueError.self) {
            try [5.0].zTransformL2()
        }
    }

    @Test func allEqualValuesThrows() {
        #expect(throws: UncertainValueError.self) {
            try [7.0, 7.0, 7.0].zTransformL2()
        }
    }

    // MARK: - Permutation & Reflection Invariance

    @Test func permutationInvariance() throws {
        let values = [2.7, 8.1, 3.5, 11.0, 6.3, 1.9, 4.4]
        let z = try values.zTransformL2()

        let permuted = [8.1, 4.4, 1.9, 11.0, 2.7, 6.3, 3.5]
        let zPerm = try permuted.zTransformL2()

        let originalOrder = [1, 6, 5, 3, 0, 4, 2]
        for (permIdx, origIdx) in originalOrder.enumerated() {
            #expect(isClose(zPerm[permIdx], z[origIdx]))
        }
    }

    @Test func negationReflection() throws {
        let values = [2.0, 5.0, 8.0, 3.0, 6.0]
        let negated = values.map { -$0 }

        let z = try values.zTransformL2()
        let zNeg = try negated.zTransformL2()

        for (a, b) in zip(z, zNeg) {
            #expect(isClose(a, -b))
        }
    }

    // MARK: - Larger Datasets

    @Test func twentyPointInvariants() throws {
        let values = (1...20).map { Double($0) * 1.7 - 3.2 }
        let z = try values.zTransformL2()

        #expect(z.count == 20)
        #expect(isClose(z.reduce(0, +), 0.0, accuracy: 1e-9))

        let zMean = z.reduce(0, +) / Double(z.count)
        let variance = z.map { ($0 - zMean) * ($0 - zMean) }.reduce(0, +) / Double(z.count - 1)
        #expect(isClose(Darwin.sqrt(variance), 1.0, accuracy: 1e-9))
    }

    // MARK: - Numerical Stability

    @Test func extremeLargeScale() throws {
        let scale = 1e100
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale, 5.0 * scale]
        let z = try values.zTransformL2()

        for value in z { #expect(value.isFinite) }
        #expect(isClose(z.reduce(0, +), 0.0, accuracy: 1e-5))
    }

    @Test func extremeSmallScale() throws {
        let scale = 1e-100
        let values = [1.0 * scale, 2.0 * scale, 3.0 * scale, 4.0 * scale, 5.0 * scale]
        let z = try values.zTransformL2()

        for value in z { #expect(value.isFinite) }
        #expect(isClose(z.reduce(0, +), 0.0, accuracy: 1e-5))
    }

    @Test func nearlyEqualValues() throws {
        let base = 1_000_000.0
        let values = [base, base + 1e-6, base + 2e-6, base + 3e-6]
        let z = try values.zTransformL2()

        for value in z { #expect(value.isFinite) }
        #expect(isClose(z.reduce(0, +), 0.0, accuracy: 1e-5))
    }
}

struct ZTransformUncertainValueTests {
    // MARK: - Error-Free Inputs

    @Test func errorFreeInputsProduceErrorFreeOutputs() throws {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0].map { UncertainValue.errorFree($0) }
        let z = try values.zTransformL2()

        #expect(z.count == 5)
        for uv in z {
            #expect(uv.absoluteError == 0.0)
        }
    }

    @Test func errorFreeZScoresMatchDoubleVersion() throws {
        let raw = [2.7, 8.1, 3.5, 11.0, 6.3]
        let uvs = raw.map { UncertainValue.errorFree($0) }

        let zDouble = try raw.zTransformL2()
        let zUV = try uvs.zTransformL2()

        for (d, uv) in zip(zDouble, zUV) {
            #expect(isClose(uv.value, d))
        }
    }

    // MARK: - Error Propagation via Numerical Differentiation

    @Test func errorPropagationMatchesNumericalDerivatives() throws {
        let baseValues = [10.0, 20.0, 30.0]
        let errors = [1.0, 2.0, 3.0]
        let uvs = zip(baseValues, errors).map { UncertainValue($0, absoluteError: $1) }

        let result = try uvs.zTransformL2()
        let eps = TestConstants.perturbationEpsilon

        for i in 0..<baseValues.count {
            var expectedErrorSq = 0.0

            for j in 0..<baseValues.count {
                var perturbed = baseValues
                perturbed[j] += eps
                let zPlus = try perturbed.zTransformL2()

                perturbed[j] = baseValues[j] - eps
                let zMinus = try perturbed.zTransformL2()

                let numericalPartial = (zPlus[i] - zMinus[i]) / (2.0 * eps)
                expectedErrorSq += numericalPartial * numericalPartial * errors[j] * errors[j]
            }

            let expectedError = Darwin.sqrt(expectedErrorSq)
            #expect(
                isClose(result[i].absoluteError, expectedError, accuracy: TestConstants.numericalDiffAccuracy),
                "Δz[\(i)]: analytic=\(result[i].absoluteError) numerical=\(expectedError)"
            )
        }
    }

    @Test func analyticSensitivityMatchesNumericalDerivatives() throws {
        let baseValues = [10.0, 20.0, 30.0]
        let eps = TestConstants.perturbationEpsilon

        let zScores = try baseValues.zTransformL2()
        let sigma = try baseValues.sampleStandardDeviationL2()
        let n = Double(baseValues.count)

        for i in 0..<baseValues.count {
            for j in 0..<baseValues.count {
                var perturbed = baseValues
                perturbed[j] += eps
                let zPlus = try perturbed.zTransformL2()
                perturbed[j] = baseValues[j] - eps
                let zMinus = try perturbed.zTransformL2()

                let numericalPartial = (zPlus[i] - zMinus[i]) / (2.0 * eps)

                let kronecker = i == j ? 1.0 : 0.0
                let aij = kronecker - 1.0 / n - zScores[i] * zScores[j] / (n - 1.0)
                let analyticPartial = aij / sigma

                #expect(
                    isClose(analyticPartial, numericalPartial, accuracy: TestConstants.numericalDiffAccuracy),
                    "∂z[\(i)]/∂x[\(j)]: analytic=\(analyticPartial) numerical=\(numericalPartial)"
                )
            }
        }
    }

    // MARK: - Error Propagation Special Cases

    @Test func equalUncertaintiesSymmetricResult() throws {
        let values = [10.0, 20.0, 30.0].map { UncertainValue($0, absoluteError: 1.0) }
        let z = try values.zTransformL2()

        #expect(isClose(z[0].absoluteError, z[2].absoluteError))
    }

    @Test func singleLargeUncertaintyDominates() throws {
        let values = [
            UncertainValue(10.0, absoluteError: 5.0),
            UncertainValue(20.0, absoluteError: 0.0),
            UncertainValue(30.0, absoluteError: 0.0),
        ]
        let z = try values.zTransformL2()

        for uv in z {
            #expect(uv.absoluteError > 0)
        }

        let allSmallErrors = [
            UncertainValue(10.0, absoluteError: 0.01),
            UncertainValue(20.0, absoluteError: 0.0),
            UncertainValue(30.0, absoluteError: 0.0),
        ]
        let zSmall = try allSmallErrors.zTransformL2()

        for (large, small) in zip(z, zSmall) {
            #expect(large.absoluteError > small.absoluteError)
        }
    }

    // MARK: - Edge Cases

    @Test func emptyArrayThrows() {
        #expect(throws: UncertainValueError.self) {
            try [UncertainValue]().zTransformL2()
        }
    }

    @Test func singleElementThrows() {
        #expect(throws: UncertainValueError.self) {
            try [UncertainValue(5.0, absoluteError: 1.0)].zTransformL2()
        }
    }

    @Test func allEqualValuesThrows() {
        let values = [7.0, 7.0, 7.0].map { UncertainValue($0, absoluteError: 1.0) }
        #expect(throws: UncertainValueError.self) {
            try values.zTransformL2()
        }
    }

    // MARK: - Permutation & Reflection Invariance

    @Test func permutationPreservesMapping() throws {
        let values = [
            UncertainValue(2.0, absoluteError: 0.3),
            UncertainValue(5.0, absoluteError: 0.1),
            UncertainValue(8.0, absoluteError: 0.5),
            UncertainValue(3.0, absoluteError: 0.2),
        ]
        let z = try values.zTransformL2()

        let permuted = [values[2], values[0], values[3], values[1]]
        let zPerm = try permuted.zTransformL2()

        let mapping = [2, 0, 3, 1]
        for (permIdx, origIdx) in mapping.enumerated() {
            #expect(isClose(zPerm[permIdx].value, z[origIdx].value))
            #expect(isClose(zPerm[permIdx].absoluteError, z[origIdx].absoluteError))
        }
    }

    @Test func negationReflectsValues() throws {
        let values = [
            UncertainValue(2.0, absoluteError: 0.3),
            UncertainValue(5.0, absoluteError: 0.1),
            UncertainValue(8.0, absoluteError: 0.5),
        ]
        let negated = values.map { UncertainValue(-$0.value, absoluteError: $0.absoluteError) }

        let z = try values.zTransformL2()
        let zNeg = try negated.zTransformL2()

        for (a, b) in zip(z, zNeg) {
            #expect(isClose(a.value, -b.value))
            #expect(isClose(a.absoluteError, b.absoluteError))
        }
    }

    // MARK: - Mixed Errors

    @Test func mixedZeroNonzeroErrors() throws {
        let values = [
            UncertainValue(10.0, absoluteError: 0.5),
            UncertainValue(20.0, absoluteError: 0.0),
            UncertainValue(30.0, absoluteError: 0.0),
            UncertainValue(40.0, absoluteError: 0.0),
            UncertainValue(50.0, absoluteError: 0.8),
        ]
        let z = try values.zTransformL2()

        for uv in z {
            #expect(uv.absoluteError >= 0)
            #expect(uv.value.isFinite)
        }
        let hasNonzeroError = z.contains { $0.absoluteError > 0 }
        #expect(hasNonzeroError)

        let zValues = z.map(\.value)
        #expect(isClose(zValues.reduce(0, +), 0.0, accuracy: 1e-10))
    }

    // MARK: - Larger Datasets

    @Test func twentyPointErrorPropagation() throws {
        let values = (1...20).map {
            UncertainValue(Double($0) * 2.5, absoluteError: 0.3)
        }
        let z = try values.zTransformL2()

        #expect(z.count == 20)
        for uv in z { #expect(uv.value.isFinite && uv.absoluteError.isFinite) }

        let zValues = z.map(\.value)
        #expect(isClose(zValues.reduce(0, +), 0.0, accuracy: 1e-9))

        let zMean = zValues.reduce(0, +) / Double(z.count)
        let variance = zValues.map { ($0 - zMean) * ($0 - zMean) }.reduce(0, +) / Double(z.count - 1)
        #expect(isClose(Darwin.sqrt(variance), 1.0, accuracy: 1e-9))
    }

    // MARK: - Numerical Stability

    @Test func extremeScaleWithErrors() throws {
        let scale = 1e80
        let values = [1.0, 2.0, 3.0, 4.0, 5.0].map {
            UncertainValue($0 * scale, absoluteError: 0.1 * scale)
        }
        let z = try values.zTransformL2()

        for uv in z { #expect(uv.value.isFinite && uv.absoluteError.isFinite) }
    }

    // MARK: - Ground Truth (verified against NumPy reference)

    @Test func groundTruth8PointLabRealistic() throws {
        let inputs = [
            (2.31, 0.15), (4.67, 0.22), (1.98, 0.18), (5.43, 0.31),
            (3.21, 0.12), (6.78, 0.25), (4.12, 0.19), (3.89, 0.14),
        ]
        let expected = [
            (-1.090673295273423e+00, 8.328640153890508e-02),
            ( 3.896941968015035e-01, 1.290758630822913e-01),
            (-1.297673834419494e+00, 8.789316476177697e-02),
            ( 8.664227111985138e-01, 1.613428648262272e-01),
            (-5.261263703295954e-01, 7.497536160060680e-02),
            ( 1.713243098614256e+00, 1.063915552392782e-01),
            ( 4.469329822471975e-02, 1.130332313981344e-01),
            (-9.957980481648077e-02, 8.742197373063132e-02),
        ]

        let values = inputs.map { UncertainValue($0.0, absoluteError: $0.1) }
        let z = try values.zTransformL2()

        for (i, (expVal, expErr)) in expected.enumerated() {
            #expect(isClose(z[i].value, expVal), "z[\(i)] value: \(z[i].value) vs \(expVal)")
            #expect(isClose(z[i].absoluteError, expErr), "z[\(i)] error: \(z[i].absoluteError) vs \(expErr)")
        }
    }

    @Test func groundTruthMixedZeroNonzeroErrors() throws {
        let inputs = [
            (10.0, 0.5), (20.0, 0.0), (30.0, 1.2), (40.0, 0.0), (50.0, 0.8),
        ]
        let expected = [
            (-1.264911064067352e+00, 2.219909908081857e-02),
            (-6.324555320336759e-01, 1.975854245636555e-02),
            ( 0.000000000000000e+00, 6.187729793712715e-02),
            ( 6.324555320336759e-01, 2.529822128134704e-02),
            ( 1.264911064067352e+00, 2.607680962081060e-02),
        ]

        let values = inputs.map { UncertainValue($0.0, absoluteError: $0.1) }
        let z = try values.zTransformL2()

        for (i, (expVal, expErr)) in expected.enumerated() {
            #expect(isClose(z[i].value, expVal), "z[\(i)] value")
            #expect(isClose(z[i].absoluteError, expErr), "z[\(i)] error")
        }
    }

    @Test func groundTruthNegativeValues() throws {
        let inputs = [
            (-5.2, 0.4), (-1.8, 0.3), (0.3, 0.5), (2.7, 0.2), (-3.1, 0.6),
        ]
        let expected = [
            (-1.239710799114239e+00, 9.524868346043945e-02),
            (-1.246270115511669e-01, 9.971888238941229e-02),
            ( 5.641012101789659e-01, 1.246025597489810e-01),
            ( 1.351219177870546e+00, 7.537952585137749e-02),
            (-5.509825773841062e-01, 1.533898298166060e-01),
        ]

        let values = inputs.map { UncertainValue($0.0, absoluteError: $0.1) }
        let z = try values.zTransformL2()

        for (i, (expVal, expErr)) in expected.enumerated() {
            #expect(isClose(z[i].value, expVal), "z[\(i)] value")
            #expect(isClose(z[i].absoluteError, expErr), "z[\(i)] error")
        }
    }

    @Test func groundTruth15Point() throws {
        let inputs = [
            ( 8.12, 0.27), (19.06, 0.37), (14.91, 0.57), (12.37, 0.49),
            ( 3.96, 0.36), ( 3.96, 0.65), ( 2.10, 0.23), (17.46, 0.36),
            (12.42, 0.43), (14.45, 0.51), ( 1.39, 0.81), (19.43, 0.28),
            (16.82, 0.56), ( 5.03, 0.63), ( 4.45, 0.14),
        ]
        let expected = [
            (-3.490920293546999e-01, 4.373774089137660e-02),
            ( 1.329372723563738e+00, 5.340959885437278e-02),
            ( 6.926607743305097e-01, 8.096078165140555e-02),
            ( 3.029623764865578e-01, 7.194031326775609e-02),
            (-9.873382242487307e-01, 5.572118177209262e-02),
            (-9.873382242487307e-01, 9.011111355681227e-02),
            (-1.272707917158081e+00, 4.443108493244737e-02),
            ( 1.083893417835264e+00, 5.295310494829306e-02),
            ( 3.106336047905727e-01, 6.375105946114742e-02),
            ( 6.220854739335734e-01, 7.342637887715416e-02),
            (-1.381639359075091e+00, 1.024051982775024e-01),
            ( 1.386139813013447e+00, 4.493907535425987e-02),
            ( 9.857016955438749e-01, 7.731809268498667e-02),
            (-8.231739385428141e-01, 8.908838633719773e-02),
            (-9.121601868693857e-01, 3.410675598008103e-02),
        ]

        let values = inputs.map { UncertainValue($0.0, absoluteError: $0.1) }
        let z = try values.zTransformL2()

        for (i, (expVal, expErr)) in expected.enumerated() {
            #expect(isClose(z[i].value, expVal), "z[\(i)] value")
            #expect(isClose(z[i].absoluteError, expErr), "z[\(i)] error")
        }
    }

    @Test func groundTruthN2Minimum() throws {
        let values = [
            UncertainValue(3.0, absoluteError: 0.5),
            UncertainValue(7.0, absoluteError: 1.0),
        ]
        let z = try values.zTransformL2()

        #expect(isClose(z[0].value, -7.071067811865475e-01))
        #expect(isClose(z[1].value,  7.071067811865475e-01))
        #expect(z[0].absoluteError < 1e-15)
        #expect(z[1].absoluteError < 1e-15)
    }

    @Test func groundTruthUniformErrors() throws {
        let inputs = [
            (1.0, 0.5), (3.0, 0.5), (5.0, 0.5), (7.0, 0.5), (9.0, 0.5),
        ]
        let expected = [
            (-1.264911064067352e+00, 1.000000000000000e-01),
            (-6.324555320336759e-01, 1.322875655532295e-01),
            ( 0.000000000000000e+00, 1.414213562373095e-01),
            ( 6.324555320336759e-01, 1.322875655532295e-01),
            ( 1.264911064067352e+00, 1.000000000000000e-01),
        ]

        let values = inputs.map { UncertainValue($0.0, absoluteError: $0.1) }
        let z = try values.zTransformL2()

        for (i, (expVal, expErr)) in expected.enumerated() {
            #expect(isClose(z[i].value, expVal), "z[\(i)] value")
            #expect(isClose(z[i].absoluteError, expErr), "z[\(i)] error")
        }
    }
}

// MARK: - Test Helpers

private func isClose(_ a: Double, _ b: Double, accuracy: Double = TestConstants.defaultAccuracy) -> Bool {
    abs(a - b) <= accuracy
}
