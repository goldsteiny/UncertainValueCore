//
//  SignumProvidingBase+Array.swift
//  UncertainValueCore
//
//  Created by Yaron Goldstein on 2026-01-06.
//

extension Array where Element == Signum {
    /// Computes the product of signs (negative count parity).
    /// - Returns: `.negative` if odd number of negatives, `.positive` otherwise.
    public func product() -> Signum {
        reduce(.positive) { result, nextSignum in
            switch (result, nextSignum) {
            case (.positive, _): return nextSignum
            case (.negative, _): return nextSignum.flipped
            case (_, .zero): return .zero
            case (.zero, _): return .zero
            }
        }
    }
}
