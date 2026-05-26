import Testing
@testable import UncertainValueBinning

struct BinIntervalTests {

    // MARK: - Valid construction

    @Test func validIntervalInitializes() {
        let interval = BinInterval(lowerBound: 0, upperBound: 1)
        #expect(interval != nil)
    }

    @Test func boundsAreStoredExactly() throws {
        let interval = try #require(BinInterval(lowerBound: 1.5, upperBound: 3.7))
        #expect(interval.lowerBound == 1.5)
        #expect(interval.upperBound == 3.7)
    }

    @Test func negativeRangeIsValid() {
        #expect(BinInterval(lowerBound: -10, upperBound: -1) != nil)
    }

    @Test func negativeToPositiveRangeIsValid() {
        #expect(BinInterval(lowerBound: -5, upperBound: 5) != nil)
    }

    @Test func verySmallWidthIsValid() {
        #expect(BinInterval(lowerBound: 0, upperBound: 1e-15) != nil)
    }

    @Test func veryLargeRangeIsValid() {
        #expect(BinInterval(lowerBound: -1e300, upperBound: 1e300) != nil)
    }

    @Test func largeChannelNumbersAreValid() {
        // Detector channel indices can be large integers
        #expect(BinInterval(lowerBound: 1023, upperBound: 1024) != nil)
    }

    // MARK: - Invalid construction

    @Test func zeroWidthIsInvalid() {
        #expect(BinInterval(lowerBound: 1, upperBound: 1) == nil)
    }

    @Test func negativeWidthIsInvalid() {
        #expect(BinInterval(lowerBound: 5, upperBound: 3) == nil)
    }

    @Test func infiniteLowerBoundIsInvalid() {
        #expect(BinInterval(lowerBound: .infinity, upperBound: 1) == nil)
    }

    @Test func negativeInfiniteLowerBoundIsInvalid() {
        #expect(BinInterval(lowerBound: -.infinity, upperBound: 1) == nil)
    }

    @Test func infiniteUpperBoundIsInvalid() {
        #expect(BinInterval(lowerBound: 0, upperBound: .infinity) == nil)
    }

    @Test func negativeInfiniteUpperBoundIsInvalid() {
        #expect(BinInterval(lowerBound: -1, upperBound: -.infinity) == nil)
    }

    @Test func nanLowerBoundIsInvalid() {
        #expect(BinInterval(lowerBound: .nan, upperBound: 1) == nil)
    }

    @Test func nanUpperBoundIsInvalid() {
        #expect(BinInterval(lowerBound: 0, upperBound: .nan) == nil)
    }

    @Test func bothBoundsNanIsInvalid() {
        #expect(BinInterval(lowerBound: .nan, upperBound: .nan) == nil)
    }

    // MARK: - Derived properties: center

    @Test func centerIsHalfway() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 4))
        #expect(interval.center == 2)
    }

    @Test func centerForNegativeRange() throws {
        let interval = try #require(BinInterval(lowerBound: -4, upperBound: -2))
        #expect(interval.center == -3)
    }

    @Test func centerForCrossingZero() throws {
        let interval = try #require(BinInterval(lowerBound: -1, upperBound: 1))
        #expect(interval.center == 0)
    }

    @Test func centerForUnitInterval() throws {
        let interval = try #require(BinInterval(lowerBound: 2, upperBound: 3))
        #expect(interval.center == 2.5)
    }

    // MARK: - Derived properties: width

    @Test func widthIsUpperMinusLower() throws {
        let interval = try #require(BinInterval(lowerBound: 2, upperBound: 5))
        #expect(interval.width == 3)
    }

    @Test func widthForFractionalBounds() throws {
        let interval = try #require(BinInterval(lowerBound: 0.1, upperBound: 0.4))
        #expect(abs(interval.width - 0.3) < 1e-15)
    }

    @Test func widthIsAlwaysPositive() throws {
        let interval = try #require(BinInterval(lowerBound: -10, upperBound: -1))
        #expect(interval.width > 0)
        #expect(interval.width == 9)
    }

    // MARK: - Adjacency (half-open [a,b) convention)

    @Test func adjacentIntervalsShareBoundary() throws {
        let first = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let second = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        #expect(first.upperBound == second.lowerBound)
    }

    @Test func multipleAdjacentBinsChain() throws {
        let bins = try (0..<5).map { i -> BinInterval in
            try #require(BinInterval(lowerBound: Double(i), upperBound: Double(i + 1)))
        }
        for i in 0..<4 {
            #expect(bins[i].upperBound == bins[i + 1].lowerBound)
        }
    }

    // MARK: - Equatable / Hashable

    @Test func equalIntervalsAreEqual() throws {
        let a = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        let b = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        #expect(a == b)
    }

    @Test func differentLowerBoundsAreNotEqual() throws {
        let a = try #require(BinInterval(lowerBound: 0, upperBound: 2))
        let b = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        #expect(a != b)
    }

    @Test func differentUpperBoundsAreNotEqual() throws {
        let a = try #require(BinInterval(lowerBound: 0, upperBound: 2))
        let b = try #require(BinInterval(lowerBound: 0, upperBound: 3))
        #expect(a != b)
    }

    @Test func equalIntervalsHaveSameHashValue() throws {
        let a = try #require(BinInterval(lowerBound: 1.5, upperBound: 2.5))
        let b = try #require(BinInterval(lowerBound: 1.5, upperBound: 2.5))
        #expect(a.hashValue == b.hashValue)
    }

    @Test func canBeUsedInSet() throws {
        let a = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let b = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        let s: Set<BinInterval> = [a, b, a]
        #expect(s.count == 2)
    }

    // MARK: - CustomStringConvertible

    @Test func descriptionUsesHalfOpenBrackets() throws {
        let interval = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        #expect(interval.description == "[1.0, 2.0)")
    }

    @Test func descriptionForNegativeRange() throws {
        let interval = try #require(BinInterval(lowerBound: -3, upperBound: -1))
        #expect(interval.description == "[-3.0, -1.0)")
    }
}
