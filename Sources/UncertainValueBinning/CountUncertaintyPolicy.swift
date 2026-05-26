import Foundation

public struct CountUncertaintyPolicy: Codable, Hashable, Sendable {
    public let threshold: Int?

    public init(threshold: Int? = nil) {
        guard let threshold, threshold > 0 else {
            self.threshold = nil
            return
        }
        self.threshold = threshold
    }

    public func absoluteError(for count: Int) -> Double {
        precondition(count >= 0, "absoluteError(for:) requires a non-negative count, got \(count)")
        return usesLowCountApproximation(for: count)
            ? Self.lowCountApproximation(for: count)
            : Self.squareRootApproximation(for: count)
    }

    public func absoluteErrors(for counts: [Int]) -> [Double] {
        counts.map(absoluteError(for:))
    }

    func usesLowCountApproximation(for count: Int) -> Bool {
        threshold.map { count < $0 } ?? false
    }

    public static func squareRootApproximation(for count: Int) -> Double {
        precondition(count >= 0, "squareRootApproximation(for:) requires a non-negative count, got \(count)")
        return sqrt(Double(count))
    }

    public static func lowCountApproximation(for count: Int) -> Double {
        precondition(count >= 0, "lowCountApproximation(for:) requires a non-negative count, got \(count)")
        return 1.0 + sqrt(Double(count) + 0.75)
    }
}
