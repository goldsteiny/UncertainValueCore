//
//  ValueProviding+Array.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for value/error protocols.
//

import Foundation

public extension Array where Element: ValueProviding {
    /// Array of central values.
    var values: [Element.Scalar] {
        map(\.value)
    }
}

public extension Array where Element: RelativeErrorProviding {
    /// Array of relative errors.
    var relativeErrors: [Element.Scalar] {
        map(\.relativeError)
    }
    
    var allErrorFree: Bool {
        allSatisfy(\.isErrorFree)
    }
}

public extension Array where Element: AbsoluteErrorProviding {
    /// Array of absolute errors.
    var absoluteErrors: [Element.Scalar] {
        map(\.absoluteError)
    }
}

public extension Array where Element: RelativeErrorProviding, Element.Scalar == Double {
    /// Computes the norm of the relative error vector using the specified strategy.
    func relativeErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(relativeErrors, using: strategy)
    }
}

public extension Array where Element: AbsoluteErrorProviding, Element.Scalar == Double {
    /// Computes the norm of the absolute error vector using the specified strategy.
    func absoluteErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(absoluteErrors, using: strategy)
    }
}
