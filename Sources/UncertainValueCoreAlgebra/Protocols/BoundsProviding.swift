//
//  BoundsProviding.swift
//  UncertainValueCoreAlgebra
//
//  Protocol for providing confidence interval bounds around a value with uncertainty.
//

import Foundation

/// Provides confidence interval bounds around a value.
///
/// Concrete bound calculations depend on the error type:
/// - **Additive bounds** (for `AbsoluteErrorProviding`): `value ± absoluteError`
/// - **Multiplicative bounds** (for `MultiplicativeErrorProviding`): `value */ multiplicativeError`
///
/// This protocol enables displaying error bars in UIs without requiring knowledge
/// of the underlying error representation.
public protocol BoundsProviding: ValueProviding {
    /// Lower confidence bound.
    ///
    /// For additive errors: `value - absoluteError`
    /// For multiplicative errors: `min(value * multiplicativeError, value / multiplicativeError)`
    var lowerBound: Scalar { get }

    /// Upper confidence bound.
    ///
    /// For additive errors: `value + absoluteError`
    /// For multiplicative errors: `max(value * multiplicativeError, value / multiplicativeError)`
    var upperBound: Scalar { get }
}

public extension BoundsProviding {
    
    /// Closed interval representing the confidence bounds.
    var bounds: ClosedRange<Scalar> {
        lowerBound...upperBound
    }
    
    /// Returns iff lowerBound == upperBound.
    var isSinglePoint: Bool {
        return lowerBound == upperBound
    }
}
