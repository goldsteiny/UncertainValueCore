import Foundation
import Testing
@testable import UncertainValueBinning

struct CountUncertaintyPolicyTests {
    @Test func squareRootPolicyUsesSqrtForAllCounts() {
        let policy = CountUncertaintyPolicy()

        #expect(policy.absoluteError(for: 0) == 0.0)
        #expect(policy.absoluteError(for: 1) == 1.0)
        #expect(policy.absoluteError(for: 4) == 2.0)
    }

    @Test func thresholdPolicyUsesLowCountApproximationBelowThresholdOnly() {
        let policy = CountUncertaintyPolicy(threshold: 3)

        #expect(isApproximatelyEqual(policy.absoluteError(for: 0), 1.0 + sqrt(0.75)))
        #expect(isApproximatelyEqual(policy.absoluteError(for: 2), 1.0 + sqrt(2.75)))
        #expect(policy.absoluteError(for: 3) == sqrt(3.0))
        #expect(policy.absoluteError(for: 4) == 2.0)
    }

    @Test func zeroThresholdNormalizesToSquareRootPolicy() {
        let policy = CountUncertaintyPolicy(threshold: 0)

        #expect(policy.threshold == nil)
        #expect(policy.absoluteError(for: 0) == 0.0)
    }

    @Test func usesLowCountApproximationReflectsThreshold() {
        let policy = CountUncertaintyPolicy(threshold: 5)

        #expect(policy.usesLowCountApproximation(for: 4) == true)
        #expect(policy.usesLowCountApproximation(for: 5) == false)
        #expect(policy.usesLowCountApproximation(for: 6) == false)
    }

    @Test func usesLowCountApproximationFalseWithNoThreshold() {
        let policy = CountUncertaintyPolicy()

        #expect(policy.usesLowCountApproximation(for: 0) == false)
        #expect(policy.usesLowCountApproximation(for: 100) == false)
    }

    @Test func absoluteErrorsBatchMatchesSingleCalls() {
        let policy = CountUncertaintyPolicy(threshold: 3)
        let counts = [0, 1, 2, 3, 4]
        let batch = policy.absoluteErrors(for: counts)
        let single = counts.map { policy.absoluteError(for: $0) }
        #expect(batch == single)
    }

    @Test func codableRoundTrip() throws {
        let policy = CountUncertaintyPolicy(threshold: 5)
        let data = try JSONEncoder().encode(policy)
        let decoded = try JSONDecoder().decode(CountUncertaintyPolicy.self, from: data)
        #expect(decoded == policy)
    }

    @Test func codableRoundTripNoThreshold() throws {
        let policy = CountUncertaintyPolicy()
        let data = try JSONEncoder().encode(policy)
        let decoded = try JSONDecoder().decode(CountUncertaintyPolicy.self, from: data)
        #expect(decoded == policy)
        #expect(decoded.threshold == nil)
    }

    // MARK: - Input validation contract

    @Test func absoluteErrorForZeroCountIsValidBoundary() {
        // count=0 is the smallest valid input. sqrt(0) = 0, so no low-count approximation.
        // This is the boundary below which absoluteError(for:) triggers a precondition failure.
        let policy = CountUncertaintyPolicy()
        #expect(policy.absoluteError(for: 0) == 0.0)
    }

    @Test func absoluteErrorsForEmptyArrayIsEmpty() {
        // Validates absoluteErrors(for:) handles the empty case without precondition issues.
        let policy = CountUncertaintyPolicy()
        #expect(policy.absoluteErrors(for: []).isEmpty)
    }

    private func isApproximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 1e-12
    }
}
