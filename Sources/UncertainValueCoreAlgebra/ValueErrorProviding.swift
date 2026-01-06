//
//  ValueErrorProviding.swift
//  UncertainValueCoreAlgebra
//
//  Protocols for values with relative/absolute error semantics.
//

import Foundation

/// Provides a scalar value.
public protocol ValueProviding: Sendable {
    associatedtype Scalar: BinaryFloatingPoint
    var value: Scalar { get }
}

public extension ValueProviding {
    /// Absolute value of the central value.
    var absoluteValue: Scalar {
        abs(value)
    }
}

/// Provides relative error as a fraction (sigma / |x|).
public protocol RelativeErrorProviding: ValueProviding {
    var relativeError: Scalar { get }
}

public extension RelativeErrorProviding {
    /// Estimated absolute error derived from relative error.
    var absoluteErrorEstimate: Scalar {
        abs(value) * relativeError
    }

    /// Multiplicative error factor (1 + relative error).
    var errorMultiplier: Scalar {
        1 + relativeError
    }
    
    /// Variance (squared uncertainty).
    var variance: Scalar {
        absoluteErrorEstimate * absoluteErrorEstimate
    }
}

/// Provides absolute error alongside relative error.
public protocol AbsoluteErrorProviding: RelativeErrorProviding {
    var absoluteError: Scalar { get }
}

public extension AbsoluteErrorProviding {
    /// Uses the stored absolute error as the estimate.
    var absoluteErrorEstimate: Scalar {
        absoluteError
    }
    
    /// Relative 1-sigma uncertainty: sigma / |x|.
    /// - Returns 0 if both value and error are 0.
    /// - Returns +infinity if value is 0 but error is non-zero.
    var relativeError: Scalar {
        let denom = absoluteValue
        guard denom > 0 else { return absoluteError == 0 ? 0 : .infinity }
        return absoluteError / denom
    }
}

// MARK: - Array Helpers

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
}

public extension Array where Element: AbsoluteErrorProviding {
    /// Array of absolute errors.
    var absoluteErrors: [Element.Scalar] {
        map(\.absoluteError)
    }
}

public extension Array where Element: AbsoluteErrorProviding, Element.Scalar == Double {
    /// Computes the norm of the absolute error vector using the specified strategy.
    func absoluteErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(absoluteErrors, using: strategy)
    }
}

public extension Array where Element: RelativeErrorProviding, Element.Scalar == Double {
    /// Computes the norm of the relative error vector using the specified strategy.
    func relativeErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(relativeErrors, using: strategy)
    }
}
