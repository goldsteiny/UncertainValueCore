//
//  SignumCollections.swift
//  UncertainValueCoreAlgebra
//
//  Signum aggregation helpers.
//

public extension Array where Element == Signum {
    /// Multiplicative sign product over the array.
    /// Empty array returns `.positive`.
    @inlinable
    func product() -> Signum {
        reduce(.positive) { partial, next in
            switch (partial, next) {
            case (.zero, _), (_, .zero):
                return .zero
            case (.positive, .positive), (.negative, .negative):
                return .positive
            case (.positive, .negative), (.negative, .positive):
                return .negative
            }
        }
    }
}
