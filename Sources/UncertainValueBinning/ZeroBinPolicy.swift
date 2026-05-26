/// Explicit policy for how zero-count bins are handled when projecting a
/// `BinnedCountSeries` to a `FitObservationSeries`.
///
/// A zero-count bin with the default `CountUncertaintyPolicy` (no threshold) produces
/// δy = 0, which gives `GaussianPeakFitter` an implicit fallback weight of 1/(1²) = 1.
/// This policy makes that decision explicit rather than silently choosing a behavior. (D4)
///
/// Lives in `UncertainValueBinning` (not `UncertainValueFitting`) so that callers who
/// configure projection parameters do not need to import the fitting target. (D6)
public enum ZeroBinPolicy: Hashable, Sendable {
    /// Include zero-count bins in the projection. The series' `CountUncertaintyPolicy`
    /// determines δy for count = 0. If δy = 0, the fitter applies its fallback weight.
    /// A warning is emitted disclosing how many zero-count bins were kept.
    case keepWithFallbackWarning

    /// Include zero-count bins, overriding δy with the Gehrels low-count approximation
    /// (1 + √0.75 ≈ 1.87) regardless of the series' policy. This gives zero-count bins
    /// a physically motivated weight without mutating the series' policy.
    case useLowCountPolicy

    /// Exclude zero-count bins from the projection entirely. The result's
    /// `excludedBinCount` reports how many were dropped.
    case excludeFromProjection
}
