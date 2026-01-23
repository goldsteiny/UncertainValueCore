//
//  CommutativeAdditiveGroup+Array.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for additive groups.
//

import Foundation

public extension Array where Element: SummableGroup {
    /// Sums all elements using the specified norm strategy.
    @inlinable
    func sum(using strategy: Element.Norm) -> Element {
        Element.sum(self, using: strategy)
    }
}


public extension Array where Element: CommutativeAdditiveGroup & Scalable {
    /// Mean of all values with error propagation using the specified norm.
    /// - Parameter strategy: The norm strategy for combining absolute errors.
    /// - Returns: Mean with combined uncertainty.
    /// - Throws: `UncertainValueError.emptyCollection` for empty array.
    func mean(using strategy: Element.Norm) throws -> Element {
        guard !isEmpty else { throw UncertainValueError.emptyCollection }
        return try sum(using: strategy).scaledDown(by: Element.Scalar(count))
    }
}
