import Testing
@testable import UncertainValueSupport

private struct AdditiveBoundedValue: AbsoluteErrorProviding, BoundsProviding {
    let value: Double
    let absoluteError: Double
}

private struct MultiplicativeBoundedValue: MultiplicativeErrorProviding, BoundsProviding {
    let value: Double
    let multiplicativeError: Double
}

struct UncertainValueSupportTests {
    @Test func normStrategiesMatchExpectedValues() {
        #expect(norm1([-3.0, 4.0]) == 7.0)
        #expect(norm2([3.0, 4.0]) == 5.0)
        #expect(abs(normp([3.0, 4.0], p: 3.0) - 4.497941445275415) < 1e-12)
        #expect(norm([3.0, 4.0], using: .l2) == 5.0)
    }

    @Test func absoluteErrorBoundsUseAdditiveInterval() {
        let value = AdditiveBoundedValue(value: 10.0, absoluteError: 0.5)

        #expect(value.relativeError == 0.05)
        #expect(value.lowerBound == 9.5)
        #expect(value.upperBound == 10.5)
        #expect(value.bounds == 9.5...10.5)
        #expect(!value.isSinglePoint)
    }

    @Test func multiplicativeBoundsRespectNegativeValues() {
        let value = MultiplicativeBoundedValue(value: -10.0, multiplicativeError: 2.0)

        #expect(value.relativeError == 1.0)
        #expect(value.lowerBound == -20.0)
        #expect(value.upperBound == -5.0)
    }

    @Test func boundedDoubleClampsNonFiniteBoundsFromProviders() {
        let value = BoundedDouble(
            from: BoundedDouble(value: 3.0, lowerBound: -.infinity, upperBound: .infinity)
        )

        #expect(value.value == 3.0)
        #expect(value.lowerBound == 3.0)
        #expect(value.upperBound == 3.0)
    }

    @Test func doublesConvertToOptionalBoundedValues() {
        let values = [1.0, 2.0, 3.0].asBoundedValues

        #expect(values == [1.0, 2.0, 3.0])
    }

    @Test func errorVectorHelpersApplySelectedNorm() {
        let values = [
            AdditiveBoundedValue(value: 2.0, absoluteError: 0.3),
            AdditiveBoundedValue(value: 4.0, absoluteError: 0.4)
        ]

        #expect(!values.allErrorFree)
        #expect(values.absoluteErrorVectorLength(using: .l2) == 0.5)
        #expect(values.relativeErrorVectorLength(using: .l1) == 0.25)
    }

    @Test func allErrorFreeUsesRelativeError() {
        let values = [
            AdditiveBoundedValue(value: 2.0, absoluteError: 0.0),
            AdditiveBoundedValue(value: 4.0, absoluteError: 0.0)
        ]

        #expect(values.allErrorFree)
    }
}
