/// Typed errors thrown by `BinnedCountSeries` construction when invariants are violated.
///
/// Each case provides enough context for a UI or import layer to explain the problem
/// to the user rather than displaying a generic failure.
public enum BinnedCountSeriesValidationError: Error, Equatable {
    case emptyBins
    case negativeCount(at: Int)
    case nonContiguousEdges(at: Int, gap: Double)
    case unsortedEdges(at: Int)
    case nonFiniteValue(at: Int)
    case invalidBinWidth
    case edgeCountMismatch(edges: Int, counts: Int)
    case nonPositiveAllocatedCount(allocatedCount: Int)
    case allocatedCountMismatch(allocatedCount: Int, totalCount: Int)
}
