import Testing
@testable import UncertainValueBinning

struct CountBinTests {

    // MARK: - Basic construction

    @Test func basicConstructionStoresProperties() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let bin = CountBin(interval: interval, count: 5)
        #expect(bin.interval == interval)
        #expect(bin.count == 5)
    }

    @Test func zeroCountBinIsValid() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let bin = CountBin(interval: interval, count: 0)
        #expect(bin.count == 0)
    }

    @Test func largeCountIsValid() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let bin = CountBin(interval: interval, count: 1_000_000)
        #expect(bin.count == 1_000_000)
    }

    @Test func intervalPropertiesPassThrough() throws {
        let interval = try #require(BinInterval(lowerBound: 2, upperBound: 5))
        let bin = CountBin(interval: interval, count: 3)
        #expect(bin.interval.lowerBound == 2)
        #expect(bin.interval.upperBound == 5)
        #expect(bin.interval.center == 3.5)
        #expect(bin.interval.width == 3)
    }

    // MARK: - Equatable / Hashable

    @Test func equalBinsAreEqual() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let a = CountBin(interval: interval, count: 7)
        let b = CountBin(interval: interval, count: 7)
        #expect(a == b)
    }

    @Test func differentCountsAreNotEqual() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let a = CountBin(interval: interval, count: 3)
        let b = CountBin(interval: interval, count: 4)
        #expect(a != b)
    }

    @Test func differentIntervalsAreNotEqual() throws {
        let i1 = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let i2 = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        let a = CountBin(interval: i1, count: 5)
        let b = CountBin(interval: i2, count: 5)
        #expect(a != b)
    }

    @Test func equalBinsHaveSameHashValue() throws {
        let interval = try #require(BinInterval(lowerBound: 10, upperBound: 20))
        let a = CountBin(interval: interval, count: 42)
        let b = CountBin(interval: interval, count: 42)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func canBeUsedInSet() throws {
        let i1 = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let i2 = try #require(BinInterval(lowerBound: 1, upperBound: 2))
        let a = CountBin(interval: i1, count: 5)
        let b = CountBin(interval: i2, count: 5)
        let s: Set<CountBin> = [a, b, a]
        #expect(s.count == 2)
    }

    // MARK: - Unchecked-component contract

    @Test func negativeCountIsPermittedAtCountBinLevel() throws {
        // CountBin is an unchecked component. Negative counts are accepted at this
        // level and caught by BinnedCountSeries, which is the aggregate enforcement
        // boundary. This test locks in the deliberate design decision.
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let bin = CountBin(interval: interval, count: -5)
        #expect(bin.count == -5)
    }

    @Test func negativeCountBinIsRejectedByBinnedCountSeries() throws {
        let interval = try #require(BinInterval(lowerBound: 0, upperBound: 1))
        let bin = CountBin(interval: interval, count: -5)
        #expect(throws: BinnedCountSeriesValidationError.negativeCount(at: 0)) {
            try BinnedCountSeries(bins: [bin], policy: CountUncertaintyPolicy(), model: .poisson)
        }
    }
}
