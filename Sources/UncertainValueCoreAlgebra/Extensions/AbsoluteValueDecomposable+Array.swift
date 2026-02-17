//
//  AbsoluteValueDecomposable+Array.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for absolute-value types.
//

public extension Array where Element: AbsoluteValueDecomposable {
    /// Array of absolute values.
    var absolutes: [Element] {
        map(\.absolute)
    }
}
