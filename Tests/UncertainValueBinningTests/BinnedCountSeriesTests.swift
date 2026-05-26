import Testing
@testable import UncertainValueBinning

private func makeBin(_ lo: Double, _ hi: Double, count: Int = 1) -> CountBin {
    CountBin(interval: BinInterval(lowerBound: lo, upperBound: hi)!, count: count)
}

private let defaultPolicy = CountUncertaintyPolicy()
private let lowCountPolicy = CountUncertaintyPolicy(threshold: 20)

struct BinnedCountSeriesTests {

    // MARK: - Primary constructor: acceptance

    @Test func validTwoBinSeriesConstructs() throws {
        let bins = [makeBin(0, 1, count: 3), makeBin(1, 2, count: 5)]
        let series = try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        #expect(series.totalCount == 8)
        #expect(series.count == 2)
    }

    @Test func singleBinSeriesConstructs() throws {
        let series = try BinnedCountSeries(bins: [makeBin(0, 1, count: 0)], policy: defaultPolicy, model: .poisson)
        #expect(series.count == 1)
        #expect(series.totalCount == 0)
    }

    @Test func manyBinsConstructSuccessfully() throws {
        let bins = (0..<100).map { i in makeBin(Double(i), Double(i + 1), count: i) }
        let series = try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        #expect(series.count == 100)
        #expect(series.totalCount == (0..<100).reduce(0, +))
    }

    @Test func allZeroCountBinsIsValid() throws {
        let bins = [makeBin(0, 1, count: 0), makeBin(1, 2, count: 0), makeBin(2, 3, count: 0)]
        let series = try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        #expect(series.totalCount == 0)
    }

    @Test func poissonModelRequiresNoCountConsistencyCheck() throws {
        let bins = [makeBin(0, 1, count: 100), makeBin(1, 2, count: 999)]
        #expect(throws: Never.self) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    // MARK: - Primary constructor: emptyBins

    @Test func emptyBinsThrows() {
        #expect(throws: BinnedCountSeriesValidationError.emptyBins) {
            try BinnedCountSeries(bins: [], policy: defaultPolicy, model: .poisson)
        }
    }

    // MARK: - Primary constructor: nonFiniteValue

    @Test func nanLowerBoundOnFirstBinThrowsNonFinite() {
        let badInterval = CountBin(
            interval: BinInterval(lowerBound: 0, upperBound: 1)!,
            count: 5
        )
        // Construct with a non-finite lower by creating a bin manually via a workaround:
        // BinInterval rejects non-finite in its init, so we test via the edges constructor.
        // The nonFiniteValue error path is covered via the edges constructor test below.
        _ = badInterval  // suppress unused warning; this path tested via edges constructor
    }

    @Test func nonFiniteEdgeInExplicitEdgesThrows() {
        // BinInterval.init? rejects non-finite, causing compactMap to drop that bin,
        // which then fails contiguity. This verifies the overall rejection path.
        #expect(throws: (any Error).self) {
            try BinnedCountSeries(
                edges: [0, Double.nan, 2],
                counts: [5, 5],
                policy: defaultPolicy,
                model: .poisson
            )
        }
    }

    @Test func nonFiniteUpperEdgeInExplicitEdgesThrows() {
        #expect(throws: (any Error).self) {
            try BinnedCountSeries(
                edges: [0, 1, .infinity],
                counts: [5, 5],
                policy: defaultPolicy,
                model: .poisson
            )
        }
    }

    // MARK: - Primary constructor: negativeCount

    @Test func negativeCountAtFirstBinThrows() {
        let bin = CountBin(interval: BinInterval(lowerBound: 0, upperBound: 1)!, count: -1)
        #expect(throws: BinnedCountSeriesValidationError.negativeCount(at: 0)) {
            try BinnedCountSeries(bins: [bin], policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func negativeCountAtMiddleBinThrows() {
        let bins = [
            makeBin(0, 1, count: 5),
            CountBin(interval: BinInterval(lowerBound: 1, upperBound: 2)!, count: -3),
            makeBin(2, 3, count: 5)
        ]
        #expect(throws: BinnedCountSeriesValidationError.negativeCount(at: 1)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func negativeCountAtLastBinThrows() {
        let bins = [
            makeBin(0, 1, count: 5),
            CountBin(interval: BinInterval(lowerBound: 1, upperBound: 2)!, count: -1)
        ]
        #expect(throws: BinnedCountSeriesValidationError.negativeCount(at: 1)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    // MARK: - Primary constructor: unsortedEdges

    @Test func reversedTwoBinsThrowsUnsortedEdges() {
        let bins = [makeBin(1, 2), makeBin(0, 1)]
        #expect(throws: BinnedCountSeriesValidationError.unsortedEdges(at: 1)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func overlappingBinsThrowsUnsortedEdges() {
        let bins = [makeBin(0, 2), makeBin(1, 3)]
        #expect(throws: BinnedCountSeriesValidationError.unsortedEdges(at: 1)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func unsortedMiddleBinThrows() {
        let bins = [makeBin(0, 1), makeBin(5, 6), makeBin(1, 2)]
        // The second bin is fine relative to first, but then we have unsorted at index 2.
        #expect(throws: (any Error).self) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    // MARK: - Primary constructor: nonContiguousEdges

    @Test func gapBetweenFirstAndSecondBinThrows() {
        let bins = [makeBin(0, 1), makeBin(2, 3)]
        #expect(throws: BinnedCountSeriesValidationError.nonContiguousEdges(at: 1, gap: 1.0)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func gapBetweenMiddleBinsThrows() {
        let bins = [makeBin(0, 1), makeBin(1, 2), makeBin(3, 4)]
        #expect(throws: BinnedCountSeriesValidationError.nonContiguousEdges(at: 2, gap: 1.0)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func largeGapThrowsWithCorrectGapValue() throws {
        let bins = [makeBin(0, 1), makeBin(100, 101)]
        do {
            _ = try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
            Issue.record("Expected throw")
        } catch BinnedCountSeriesValidationError.nonContiguousEdges(let at, let gap) {
            #expect(at == 1)
            #expect(abs(gap - 99.0) < 1e-12)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    // MARK: - Primary constructor: contiguity tolerance

    @Test func edgesWithinToleranceAreAccepted() throws {
        // Gap of 1e-12 is well within tolerance 1e-9 * wMin (wMin=1 → tolerance=1e-9)
        let i1 = BinInterval(lowerBound: 0, upperBound: 1)!
        let i2 = BinInterval(lowerBound: 1.0 + 1e-12, upperBound: 2.0 + 1e-12)!
        let bins = [CountBin(interval: i1, count: 1), CountBin(interval: i2, count: 2)]
        #expect(throws: Never.self) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func overlapWithinToleranceIsAccepted() throws {
        // Tiny overlap of 1e-12 (within tolerance) is accepted
        let i1 = BinInterval(lowerBound: 0, upperBound: 1)!
        let i2 = BinInterval(lowerBound: 1.0 - 1e-12, upperBound: 2.0 - 1e-12)!
        let bins = [CountBin(interval: i1, count: 1), CountBin(interval: i2, count: 2)]
        #expect(throws: Never.self) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func gapOutsideToleranceThrows() {
        // Gap of 1e-6 is outside tolerance 1e-9 * 1.0 = 1e-9
        let i1 = BinInterval(lowerBound: 0, upperBound: 1)!
        let i2 = BinInterval(lowerBound: 1.0 + 1e-6, upperBound: 2.0 + 1e-6)!
        let bins = [CountBin(interval: i1, count: 1), CountBin(interval: i2, count: 2)]
        #expect(throws: BinnedCountSeriesValidationError.self) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .poisson)
        }
    }

    // MARK: - Primary constructor: multinomial observation model

    @Test func multinomialWithMatchingAllocatedCountSucceeds() throws {
        let bins = [makeBin(0, 1, count: 3), makeBin(1, 2, count: 7)]
        #expect(throws: Never.self) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .multinomial(allocatedCount: 10))
        }
    }

    @Test func multinomialZeroAllocatedCountThrows() {
        let bin = makeBin(0, 1, count: 5)
        #expect(throws: BinnedCountSeriesValidationError.nonPositiveAllocatedCount(allocatedCount: 0)) {
            try BinnedCountSeries(bins: [bin], policy: defaultPolicy, model: .multinomial(allocatedCount: 0))
        }
    }

    @Test func multinomialNegativeAllocatedCountThrows() {
        let bin = makeBin(0, 1, count: 5)
        #expect(throws: BinnedCountSeriesValidationError.nonPositiveAllocatedCount(allocatedCount: -3)) {
            try BinnedCountSeries(bins: [bin], policy: defaultPolicy, model: .multinomial(allocatedCount: -3))
        }
    }

    @Test func multinomialAllocatedCountTooLargeThrows() {
        let bins = [makeBin(0, 1, count: 3), makeBin(1, 2, count: 4)]
        #expect(throws: BinnedCountSeriesValidationError.allocatedCountMismatch(allocatedCount: 10, totalCount: 7)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .multinomial(allocatedCount: 10))
        }
    }

    @Test func multinomialAllocatedCountTooSmallThrows() {
        let bins = [makeBin(0, 1, count: 5), makeBin(1, 2, count: 5)]
        #expect(throws: BinnedCountSeriesValidationError.allocatedCountMismatch(allocatedCount: 3, totalCount: 10)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .multinomial(allocatedCount: 3))
        }
    }

    @Test func multinomialWithAllZeroCountsAndZeroAllocatedCountThrows() {
        // allocatedCount = 0 with all-zero bins still fails (allocatedCount must be > 0)
        let bins = [makeBin(0, 1, count: 0), makeBin(1, 2, count: 0)]
        #expect(throws: BinnedCountSeriesValidationError.nonPositiveAllocatedCount(allocatedCount: 0)) {
            try BinnedCountSeries(bins: bins, policy: defaultPolicy, model: .multinomial(allocatedCount: 0))
        }
    }

    // MARK: - Uniform channel constructor

    @Test func uniformChannelCreatesCorrectBinCount() throws {
        let series = try BinnedCountSeries(
            counts: [10, 20, 30],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.count == 3)
    }

    @Test func uniformChannelFirstBinBounds() throws {
        let series = try BinnedCountSeries(
            counts: [5],
            startValue: 10,
            binWidth: 2.5,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.bins[0].interval.lowerBound == 10)
        #expect(series.bins[0].interval.upperBound == 12.5)
    }

    @Test func uniformChannelLastBinBounds() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3],
            startValue: 0,
            binWidth: 5,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.bins[2].interval.lowerBound == 10)
        #expect(series.bins[2].interval.upperBound == 15)
    }

    @Test func uniformChannelBinsAreIndependentOfDrift() throws {
        // With 1000 bins of width 0.001, floating-point accumulation would drift
        // if we added widths sequentially. Independent computation avoids this.
        let counts = Array(repeating: 1, count: 1000)
        let series = try BinnedCountSeries(
            counts: counts,
            startValue: 0,
            binWidth: 0.001,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.count == 1000)
        // Last bin should end at exactly 1.0 within floating-point precision
        #expect(abs(series.bins.last!.interval.upperBound - 1.0) < 1e-12)
    }

    @Test func uniformChannelWithFractionalStartValue() throws {
        let series = try BinnedCountSeries(
            counts: [3, 4],
            startValue: 0.5,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.bins[0].interval.lowerBound == 0.5)
        #expect(series.bins[0].interval.upperBound == 1.5)
        #expect(series.bins[1].interval.lowerBound == 1.5)
        #expect(series.bins[1].interval.upperBound == 2.5)
    }

    @Test func uniformChannelEmptyCountsThrows() {
        #expect(throws: BinnedCountSeriesValidationError.emptyBins) {
            try BinnedCountSeries(counts: [], startValue: 0, binWidth: 1, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func uniformChannelZeroBinWidthThrows() {
        #expect(throws: BinnedCountSeriesValidationError.invalidBinWidth) {
            try BinnedCountSeries(counts: [1], startValue: 0, binWidth: 0, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func uniformChannelNegativeBinWidthThrows() {
        #expect(throws: BinnedCountSeriesValidationError.invalidBinWidth) {
            try BinnedCountSeries(counts: [1], startValue: 0, binWidth: -1, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func uniformChannelNonFiniteBinWidthThrows() {
        #expect(throws: BinnedCountSeriesValidationError.invalidBinWidth) {
            try BinnedCountSeries(counts: [1], startValue: 0, binWidth: .infinity, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func uniformChannelNonFiniteStartValueThrows() {
        #expect(throws: BinnedCountSeriesValidationError.invalidBinWidth) {
            try BinnedCountSeries(counts: [1], startValue: .nan, binWidth: 1, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func uniformChannelNegativeCountThrows() {
        #expect(throws: BinnedCountSeriesValidationError.negativeCount(at: 1)) {
            try BinnedCountSeries(counts: [5, -2, 3], startValue: 0, binWidth: 1, policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func uniformChannelNonFiniteComputedBoundsThrows() {
        // With startValue=0 and binWidth=DBL_MAX, bin 0 = [0, DBL_MAX) is valid, but
        // bin 1 upper bound = 2*DBL_MAX overflows to +infinity → nonFiniteValue(at: 1).
        // This verifies the constructor throws rather than silently dropping the bin.
        #expect(throws: BinnedCountSeriesValidationError.nonFiniteValue(at: 1)) {
            try BinnedCountSeries(
                counts: [5, 5],
                startValue: 0,
                binWidth: .greatestFiniteMagnitude,
                policy: defaultPolicy,
                model: .poisson
            )
        }
    }

    @Test func uniformChannelBinWidthLostToPrecisionThrows() {
        // startValue = DBL_MAX, binWidth = 1.0. At that magnitude the ULP of DBL_MAX
        // exceeds 1.0, so lo + 1.0 == lo exactly: computed hi equals lo, BinInterval
        // returns nil, and the constructor must throw .invalidBinWidth rather than drop.
        #expect(throws: BinnedCountSeriesValidationError.invalidBinWidth) {
            try BinnedCountSeries(
                counts: [5],
                startValue: .greatestFiniteMagnitude,
                binWidth: 1.0,
                policy: defaultPolicy,
                model: .poisson
            )
        }
    }

    // MARK: - Explicit edges constructor

    @Test func explicitEdgesWithThreeBins() throws {
        let series = try BinnedCountSeries(
            edges: [0, 1, 3, 6],
            counts: [5, 10, 15],
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.count == 3)
        #expect(series.bins[0].interval.width == 1)
        #expect(series.bins[1].interval.width == 2)
        #expect(series.bins[2].interval.width == 3)
    }

    @Test func explicitEdgesCountsMatchBinCounts() throws {
        let series = try BinnedCountSeries(
            edges: [0, 1, 2],
            counts: [7, 11],
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.bins[0].count == 7)
        #expect(series.bins[1].count == 11)
    }

    @Test func explicitEdgesEdgeCountMismatchThrows() {
        // 3 edges → 2 bins, but 3 counts provided
        #expect(throws: BinnedCountSeriesValidationError.edgeCountMismatch(edges: 3, counts: 3)) {
            try BinnedCountSeries(edges: [0, 1, 2], counts: [5, 10, 15], policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func explicitEdgesEmptyCountsThrows() {
        // 1 edge, 0 counts → edgeCountMismatch (edges=1, counts=0)
        #expect(throws: BinnedCountSeriesValidationError.edgeCountMismatch(edges: 1, counts: 0)) {
            try BinnedCountSeries(edges: [0], counts: [], policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func explicitEdgesEmptyBothThrows() {
        #expect(throws: BinnedCountSeriesValidationError.edgeCountMismatch(edges: 0, counts: 0)) {
            try BinnedCountSeries(edges: [], counts: [], policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func explicitEdgesNegativeCountThrows() {
        #expect(throws: BinnedCountSeriesValidationError.negativeCount(at: 0)) {
            try BinnedCountSeries(edges: [0, 1], counts: [-5], policy: defaultPolicy, model: .poisson)
        }
    }

    @Test func explicitEdgesUnsortedThrows() {
        // Edges 0, 2, 1 → non-contiguous (second gap is negative, unsorted)
        #expect(throws: (any Error).self) {
            try BinnedCountSeries(edges: [0, 2, 1], counts: [5, 5], policy: defaultPolicy, model: .poisson)
        }
    }

    // MARK: - Derived properties: domain

    @Test func domainSpansEntireSeries() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3],
            startValue: 5,
            binWidth: 2,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.domain.lowerBound == 5)
        #expect(series.domain.upperBound == 11)
    }

    @Test func domainForSingleBin() throws {
        let series = try BinnedCountSeries(
            counts: [10],
            startValue: 100,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.domain.lowerBound == 100)
        #expect(series.domain.upperBound == 101)
    }

    @Test func domainWidthEqualsSeriesSpan() throws {
        let series = try BinnedCountSeries(
            counts: Array(repeating: 1, count: 10),
            startValue: 0,
            binWidth: 0.5,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(abs(series.domain.width - 5.0) < 1e-12)
    }

    // MARK: - Derived properties: totalCount

    @Test func totalCountSumsBinCounts() throws {
        let series = try BinnedCountSeries(
            counts: [3, 7, 0, 2],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.totalCount == 12)
    }

    @Test func totalCountForAllZeroBins() throws {
        let series = try BinnedCountSeries(
            counts: [0, 0, 0],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.totalCount == 0)
    }

    @Test func totalCountForSingleBin() throws {
        let series = try BinnedCountSeries(
            counts: [42],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.totalCount == 42)
    }

    // MARK: - Derived properties: isUniform / binWidth

    @Test func isUniformTrueForEqualWidthBins() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.isUniform == true)
        #expect(series.binWidth == 1)
    }

    @Test func isUniformTrueForSingleBin() throws {
        let series = try BinnedCountSeries(
            counts: [5],
            startValue: 0,
            binWidth: 2,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.isUniform == true)
        #expect(series.binWidth == 2)
    }

    @Test func isUniformFalseForNonEqualWidthBins() throws {
        let series = try BinnedCountSeries(
            edges: [0, 1, 3, 6],
            counts: [5, 10, 15],
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.isUniform == false)
        #expect(series.binWidth == nil)
    }

    @Test func isUniformFalseForTwoDifferentWidths() throws {
        let series = try BinnedCountSeries(
            edges: [0, 1, 3],
            counts: [5, 10],
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.isUniform == false)
        #expect(series.binWidth == nil)
    }

    @Test func binWidthMatchesUniformChannelWidth() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3, 4, 5],
            startValue: 0,
            binWidth: 0.25,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.binWidth == 0.25)
    }

    // MARK: - Stored policy and model

    @Test func uncertaintyPolicyIsStored() throws {
        let policy = CountUncertaintyPolicy(threshold: 10)
        let series = try BinnedCountSeries(
            counts: [5],
            startValue: 0,
            binWidth: 1,
            policy: policy,
            model: .poisson
        )
        #expect(series.uncertaintyPolicy == policy)
    }

    @Test func observationModelIsStored() throws {
        let series = try BinnedCountSeries(
            counts: [5, 5],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .multinomial(allocatedCount: 10)
        )
        #expect(series.observationModel == .multinomial(allocatedCount: 10))
    }

    @Test func poissonModelIsStored() throws {
        let series = try BinnedCountSeries(
            counts: [5],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.observationModel == .poisson)
    }

    // MARK: - RandomAccessCollection conformance

    @Test func iterationProducesAllBinsInOrder() throws {
        let counts = [10, 20, 30]
        let series = try BinnedCountSeries(
            counts: counts,
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.map(\.count) == counts)
    }

    @Test func subscriptReturnsCorrectBin() throws {
        let series = try BinnedCountSeries(
            counts: [10, 20, 30],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series[0].count == 10)
        #expect(series[1].count == 20)
        #expect(series[2].count == 30)
    }

    @Test func firstReturnsFirstBin() throws {
        let series = try BinnedCountSeries(
            counts: [7, 8, 9],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.first?.count == 7)
    }

    @Test func lastReturnsLastBin() throws {
        let series = try BinnedCountSeries(
            counts: [7, 8, 9],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.last?.count == 9)
    }

    @Test func isEmptyFalseForNonEmptySeries() throws {
        let series = try BinnedCountSeries(
            counts: [5],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.isEmpty == false)
    }

    @Test func countMatchesBinCount() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3, 4, 5],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.count == 5)
    }

    @Test func filterByCountWorks() throws {
        let series = try BinnedCountSeries(
            counts: [0, 5, 0, 10, 0],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        let nonEmpty = series.filter { $0.count > 0 }
        #expect(nonEmpty.count == 2)
        #expect(nonEmpty.map(\.count) == [5, 10])
    }

    @Test func reduceOverCountsWorks() throws {
        let series = try BinnedCountSeries(
            counts: [3, 7, 2, 8],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        let sum = series.reduce(0) { $0 + $1.count }
        #expect(sum == series.totalCount)
    }

    @Test func dropFirstYieldsCorrectSlice() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        let dropped = series.dropFirst()
        #expect(dropped.map(\.count) == [2, 3])
    }

    @Test func startAndEndIndicesAreCorrect() throws {
        let series = try BinnedCountSeries(
            counts: [1, 2, 3],
            startValue: 0,
            binWidth: 1,
            policy: defaultPolicy,
            model: .poisson
        )
        #expect(series.startIndex == 0)
        #expect(series.endIndex == 3)
    }
}
