//
//  MultiplicativeUncertainValue+Lists.swift
//  MultiplicativeUncertainValue
//
//  Array extensions for combining MultiplicativeUncertainValues.
//

import Foundation
import UncertainValueCore

extension Array where Element == MultiplicativeUncertainValue {
    
    /// Multiplies all values with error propagation using the specified norm.
    /// - Parameter strategy: Norm strategy for combining log-space errors.
    /// - Returns: Product with combined uncertainty.
    public func product(using strategy: NormStrategy) -> MultiplicativeUncertainValue {
        MultiplicativeUncertainValue.exp(
            map(\.logAbs).sum(using: strategy),
            withResultSign: map(\.sign).product()
        )
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
