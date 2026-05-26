/// A contiguous, bounded, half-open region [a, b) on a continuous domain axis.
///
/// Values exactly on a boundary belong to the bin starting at that boundary
/// (half-open [a, b) convention), matching `HistogramAnalyzer.binIndex(for:width:offset:)`.
public struct BinInterval: Hashable, Sendable {
    public let lowerBound: Double
    public let upperBound: Double

    /// Returns nil when `lowerBound >= upperBound` or either value is non-finite.
    public init?(lowerBound: Double, upperBound: Double) {
        guard lowerBound.isFinite, upperBound.isFinite, lowerBound < upperBound else { return nil }
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    public var center: Double { (lowerBound + upperBound) / 2 }
    public var width: Double { upperBound - lowerBound }
}

extension BinInterval: CustomStringConvertible {
    public var description: String { "[\(lowerBound), \(upperBound))" }
}
