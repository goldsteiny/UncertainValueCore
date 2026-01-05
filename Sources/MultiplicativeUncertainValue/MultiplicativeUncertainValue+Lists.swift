//
//  MultiplicativeUncertainValue+Lists.swift
//  MultiplicativeUncertainValue
//
//  Array extensions for combining MultiplicativeUncertainValues.
//

import Foundation
import UncertainValueCore

// MARK: - Protocol-Required Static Method

extension MultiplicativeUncertainValue {
    /// Computes the product of an array of values with error propagation using the specified norm.
    ///
    /// This is the primitive operation for the `UncertainMultiplicative` protocol.
    /// Uses log-space formula: product = exp(sum(logAbs)), with sign = parity of negative count.
    ///
    /// - Parameters:
    ///   - values: Array of values to multiply.
    ///   - strategy: Norm strategy for combining log-space errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    public static func product(_ values: [MultiplicativeUncertainValue], using strategy: NormStrategy) -> MultiplicativeUncertainValue {
        guard !values.isEmpty else { return .one }
        let sumLogAbs = UncertainValue.sum(values.map(\.logAbs), using: strategy)
        let productSign = values.map(\.sign).product()
        return MultiplicativeUncertainValue.exp(sumLogAbs, withResultSign: productSign)
    }
}

// MARK: - Array Helpers

extension Array where Element == MultiplicativeUncertainValue {

    /// Multiplies all values with error propagation using the specified norm.
    ///
    /// Delegates to `MultiplicativeUncertainValue.product(_:using:)`.
    ///
    /// - Parameter strategy: Norm strategy for combining log-space errors.
    /// - Returns: Product with combined uncertainty. Empty array returns `.one`.
    public func product(using strategy: NormStrategy) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue.product(self, using: strategy)
    }
}

extension Array where Element == FloatingPointSign {
    /// Computes the product of signs (negative count parity).
    /// - Returns: `.minus` if odd number of negatives, `.plus` otherwise.
    public func product() -> FloatingPointSign {
        reduce(.plus) { result, nextSign in
            switch (result, nextSign) {
            case (.plus, _): return nextSign
            case (.minus, .plus): return .minus
            case (.minus, .minus): return .plus
            }
        }
    }
}
