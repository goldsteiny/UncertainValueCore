//
//  AbsoluteValueCollections.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for absolute-value types.
//

public extension Array where Element: AbsoluteValueDecomposable {
    /// Array of absolute values.
    @inlinable
    var absolutes: [Element] {
        map(\.absolute)
    }
}
