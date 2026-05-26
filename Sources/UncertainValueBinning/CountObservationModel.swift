/// The statistical regime governing how operations interpret the counts in a `BinnedCountSeries`.
///
/// This is a *statistical regime*, not source provenance. It does not record where data came
/// from — only which sampling model governs uncertainty computation and correlation structure.
public enum CountObservationModel: Hashable, Sendable {
    /// Bin counts are independent Poisson random variables. Total count is random.
    /// Appropriate for detector spectra, radioactive decay, photon counting.
    case poisson

    /// Bin counts are multinomial with a fixed total. The `allocatedCount` equals the number
    /// of observations allocated across these bins — use `HistogramAnalysis.summary.usedCount`,
    /// not `totalCount`, so that dropped non-finite values do not inflate the fixed total.
    case multinomial(allocatedCount: Int)

    /// Advisory early validation factory. Returns nil when `allocatedCount <= 0`.
    ///
    /// The enum case `.multinomial(allocatedCount:)` remains directly callable (Swift limitation);
    /// `BinnedCountSeries` is the enforcement boundary for the full consistency check.
    public static func validatedMultinomial(allocatedCount: Int) -> CountObservationModel? {
        guard allocatedCount > 0 else { return nil }
        return .multinomial(allocatedCount: allocatedCount)
    }
}

extension CountObservationModel: Codable {
    private enum CodingKeys: String, CodingKey {
        case regime
        case allocatedCount
    }

    private enum RegimeValue: String {
        case poisson
        case multinomial
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .poisson:
            try container.encode(RegimeValue.poisson.rawValue, forKey: .regime)
        case .multinomial(let allocatedCount):
            try container.encode(RegimeValue.multinomial.rawValue, forKey: .regime)
            try container.encode(allocatedCount, forKey: .allocatedCount)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let regimeString = try container.decode(String.self, forKey: .regime)
        guard let regime = RegimeValue(rawValue: regimeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .regime,
                in: container,
                debugDescription: "Unknown regime '\(regimeString)'"
            )
        }
        switch regime {
        case .poisson:
            self = .poisson
        case .multinomial:
            let allocatedCount = try container.decode(Int.self, forKey: .allocatedCount)
            guard allocatedCount > 0 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .allocatedCount,
                    in: container,
                    debugDescription: "allocatedCount must be > 0, got \(allocatedCount)"
                )
            }
            self = .multinomial(allocatedCount: allocatedCount)
        }
    }
}
