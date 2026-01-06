//
//  SignMagnitudeProviding+Array.swift
//  UncertainValueCore
//
//  Created by Yaron Goldstein on 2026-01-06.
//

public extension Array where Element: SignMagnitudeProviding {
    /// Array of absolute values.
    var absolutes: [Element] {
        map(\.absolute)
    }
}
