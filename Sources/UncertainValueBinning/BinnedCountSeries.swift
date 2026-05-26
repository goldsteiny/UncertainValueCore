/// An ordered, contiguous, non-overlapping partition of a domain interval into bins,
/// each carrying a non-negative integer count.
///
/// This is the central aggregate of the binned data domain. All invariants are enforced
/// at construction; construction throws `BinnedCountSeriesValidationError` on violation.
///
/// Not Codable in Phase 1 — the aggregate is transient (constructed on demand, never
/// persisted). Phase 2 persistence uses `BinnedCountSeriesPayload` with its own
/// versioned Codable shape.
public struct BinnedCountSeries: Sendable {
    public let bins: [CountBin]
    public let uncertaintyPolicy: CountUncertaintyPolicy
    public let observationModel: CountObservationModel

    // Tolerance factor for contiguity checks: ε = contiguityTolerance × wMin.
    // Using a relative factor against the minimum bin width avoids false failures
    // for calibrated axes where bin widths span many orders of magnitude.
    private static let contiguityTolerance: Double = 1e-9

    // MARK: - Derived properties

    /// The full domain interval spanned by the series: [first bin lower, last bin upper).
    ///
    /// Safe force-unwrap: construction guarantees non-empty bins with finite,
    /// ordered bounds, so first.lowerBound < last.upperBound holds by invariant.
    public var domain: BinInterval {
        BinInterval(lowerBound: bins.first!.interval.lowerBound,
                    upperBound: bins.last!.interval.upperBound)!
    }

    public var totalCount: Int {
        bins.reduce(0) { $0 + $1.count }
    }

    /// True when all bins share the same width within floating-point tolerance
    /// (1e-9 × minimum width).
    public var isUniform: Bool {
        guard bins.count > 1 else { return true }
        let widths = bins.map(\.interval.width)
        let wMin = widths.min()!
        let tolerance = Self.contiguityTolerance * wMin
        return widths.allSatisfy { abs($0 - wMin) <= tolerance }
    }

    /// The common bin width when uniform, nil when non-uniform.
    public var binWidth: Double? {
        isUniform ? bins.first?.interval.width : nil
    }

    // MARK: - Primary constructor

    /// Constructs a validated series from an explicit array of bins.
    ///
    /// Validates: non-empty, finite bounds, non-negative counts, sorted,
    /// contiguous (within tolerance), and observation model consistency.
    public init(
        bins: [CountBin],
        policy: CountUncertaintyPolicy,
        model: CountObservationModel
    ) throws {
        guard !bins.isEmpty else {
            throw BinnedCountSeriesValidationError.emptyBins
        }

        // functional-style: approved loop - throwing index-specific validation errors is clearer with direct iteration.
        for (index, bin) in bins.enumerated() {
            guard bin.interval.lowerBound.isFinite, bin.interval.upperBound.isFinite else {
                throw BinnedCountSeriesValidationError.nonFiniteValue(at: index)
            }
            guard bin.count >= 0 else {
                throw BinnedCountSeriesValidationError.negativeCount(at: index)
            }
        }

        let wMin = bins.map(\.interval.width).min()!
        let tolerance = Self.contiguityTolerance * wMin

        // functional-style: approved loop - adjacent-bin comparison with tolerance is clearer as explicit control flow.
        for index in 1..<bins.count {
            let prev = bins[index - 1]
            let curr = bins[index]
            let gap = curr.interval.lowerBound - prev.interval.upperBound
            if gap < -tolerance {
                throw BinnedCountSeriesValidationError.unsortedEdges(at: index)
            }
            if gap > tolerance {
                throw BinnedCountSeriesValidationError.nonContiguousEdges(at: index, gap: gap)
            }
        }

        if case .multinomial(let allocatedCount) = model {
            guard allocatedCount > 0 else {
                throw BinnedCountSeriesValidationError.nonPositiveAllocatedCount(allocatedCount: allocatedCount)
            }
            let totalCount = bins.reduce(0) { $0 + $1.count }
            guard allocatedCount == totalCount else {
                throw BinnedCountSeriesValidationError.allocatedCountMismatch(
                    allocatedCount: allocatedCount,
                    totalCount: totalCount
                )
            }
        }

        self.bins = bins
        self.uncertaintyPolicy = policy
        self.observationModel = model
    }

    // MARK: - Uniform channel constructor

    /// Constructs a series from a flat count array and uniform bin geometry.
    ///
    /// Each bin i has bounds `[startValue + Double(i)*binWidth, startValue + Double(i+1)*binWidth)`.
    /// Bounds are computed independently per bin to avoid floating-point drift.
    public init(
        counts: [Int],
        startValue: Double,
        binWidth: Double,
        policy: CountUncertaintyPolicy,
        model: CountObservationModel
    ) throws {
        guard binWidth > 0, binWidth.isFinite, startValue.isFinite else {
            throw BinnedCountSeriesValidationError.invalidBinWidth
        }
        guard !counts.isEmpty else {
            throw BinnedCountSeriesValidationError.emptyBins
        }

        let constructed: [CountBin] = try counts.enumerated().map { (i, count) in
            let lo = startValue + Double(i) * binWidth
            let hi = startValue + Double(i + 1) * binWidth
            guard lo.isFinite, hi.isFinite else {
                throw BinnedCountSeriesValidationError.nonFiniteValue(at: i)
            }
            guard let interval = BinInterval(lowerBound: lo, upperBound: hi) else {
                // Finite bounds but lo >= hi: binWidth lost to floating-point precision at this magnitude
                throw BinnedCountSeriesValidationError.invalidBinWidth
            }
            return CountBin(interval: interval, count: count)
        }

        try self.init(bins: constructed, policy: policy, model: model)
    }

    // MARK: - Explicit edges constructor

    /// Constructs a series from explicit edge values and counts.
    ///
    /// `edges` must have exactly `counts.count + 1` elements. Edges are not silently
    /// snapped — gaps outside tolerance throw `.nonContiguousEdges`.
    public init(
        edges: [Double],
        counts: [Int],
        policy: CountUncertaintyPolicy,
        model: CountObservationModel
    ) throws {
        guard edges.count == counts.count + 1, counts.count > 0 else {
            throw BinnedCountSeriesValidationError.edgeCountMismatch(
                edges: edges.count,
                counts: counts.count
            )
        }

        let constructed: [CountBin] = try counts.enumerated().map { (i, count) in
            guard edges[i].isFinite, edges[i + 1].isFinite else {
                throw BinnedCountSeriesValidationError.nonFiniteValue(at: i)
            }
            guard let interval = BinInterval(lowerBound: edges[i], upperBound: edges[i + 1]) else {
                throw BinnedCountSeriesValidationError.unsortedEdges(at: i)
            }
            return CountBin(interval: interval, count: count)
        }

        try self.init(bins: constructed, policy: policy, model: model)
    }
}

// MARK: - RandomAccessCollection

extension BinnedCountSeries: RandomAccessCollection {
    public var startIndex: Int { bins.startIndex }
    public var endIndex: Int { bins.endIndex }

    public subscript(index: Int) -> CountBin { bins[index] }

    public func index(after i: Int) -> Int { bins.index(after: i) }
    public func index(before i: Int) -> Int { bins.index(before: i) }
    public func index(_ i: Int, offsetBy distance: Int) -> Int { bins.index(i, offsetBy: distance) }
}
