/// Strategy for assigning x-uncertainty when projecting a `BinnedCountSeries`
/// to a `FitObservationSeries`.
///
/// Lives in `UncertainValueBinning` (not `UncertainValueFitting`) so that callers who
/// configure projection parameters do not need to import the fitting target. (D6)
public enum BinXErrorModel: Hashable, Sendable {
    /// δx = 0. The bin center is treated as exact.
    ///
    /// The community standard for spectral fitting (GENIE, Maestro, ROOT). Appropriate
    /// when bin width ≪ peak sigma. `GaussianPeakFitter` degenerates to ordinary
    /// weighted regression when all δx = 0.
    case point

    /// δx = width / √12.
    ///
    /// The standard deviation of a uniform distribution on [a, b]. Appropriate when
    /// bins are wide relative to the fitted function's features. Assumes events are
    /// uniformly distributed within each bin (A6).
    case uniformSpread
}
