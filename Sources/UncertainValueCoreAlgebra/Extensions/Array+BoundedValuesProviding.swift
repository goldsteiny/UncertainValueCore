//
//  Array+BoundedValuesProviding.swift
//  UncertainValueCoreAlgebra
//
//  Convenience helpers for building bounded value arrays.
//

import Foundation

public extension Array where Element == Double {
    var asBoundedValues: [Double?] {
        map(Optional.some)
    }
}
