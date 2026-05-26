/// A single unchecked bin component: a domain interval paired with an integer count.
///
/// **Unchecked component.** `CountBin` does not validate its inputs. Negative counts and
/// other domain violations are permitted at construction and are caught by `BinnedCountSeries`,
/// which is the sole aggregate consistency boundary. Do not use `CountBin` directly in
/// contexts where `BinnedCountSeries` validation will not run.
public struct CountBin: Hashable, Sendable {
    public let interval: BinInterval
    public let count: Int

    public init(interval: BinInterval, count: Int) {
        self.interval = interval
        self.count = count
    }
}
