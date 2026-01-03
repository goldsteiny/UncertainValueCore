//
//  Double+Lists.swift
//  UncertainValueCore
//
//  Created by Yaron Goldstein on 2026-01-03.
//

extension Array where Element == Double {
    
    /// Returns the maximum absolute value in the array (always non-negative).
    /// Returns nil for an empty array.
    public var absMax: Double? {
        self.max { a, b in
            return abs(a) < abs(b)
        }.map(abs)
    }
    
    /// Sum of all elements (empty array returns 0).
    public var sum: Double {
        self.reduce(0, +)
    }
    
    /// Product of all elements (empty array returns 1).
    public var product: Double {
        self.reduce(1, *)
    }
}
