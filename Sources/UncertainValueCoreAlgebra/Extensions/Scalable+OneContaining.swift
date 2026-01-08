//
//  Scalable+OneContaining.swift
//  UncertainValueCore
//
//  Created by Yaron Goldstein on 2026-01-08.
//

public extension Scalable where Self: OneContaining {
    static func scaledOne(_ value: Scalar) throws -> Self {
        try one.scaledUp(by: value)
    }
}
