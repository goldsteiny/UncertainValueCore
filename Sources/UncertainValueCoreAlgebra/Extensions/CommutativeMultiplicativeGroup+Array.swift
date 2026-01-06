//
//  CommutativeMultiplicativeGroup+Array.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for multiplicative groups.
//

import Foundation

public extension Array where Element: CommutativeMultiplicativeGroup {
    /// Computes the product of all elements using the specified norm strategy.
    @inlinable
    func product(using strategy: Element.Norm) -> Element {
        Element.product(self, using: strategy)
    }
}
