//
//  ZeroOne.swift
//  UncertainValueCoreAlgebra
//
//  Basic identity-bearing protocols.
//

import Foundation

/// Types that can represent an additive identity.
public protocol ZeroContaining: Sendable {
    static var zero: Self { get }
    var isZero: Bool { get }
}

/// Types that can represent a multiplicative identity.
public protocol OneContaining: Sendable {
    static var one: Self { get }
    var isOne: Bool { get }
}
