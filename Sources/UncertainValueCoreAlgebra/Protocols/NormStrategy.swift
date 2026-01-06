//
//  NormStrategy.swift
//  UncertainValueCoreAlgebra
//
//  Pure norm definitions for error propagation calculations.
//

import Foundation

// MARK: - Norm Strategy

/// Strategy for combining independent uncertainties.
/// Different norms produce different propagation behavior.
public enum NormStrategy: Hashable, Sendable {
    /// L1 (Manhattan) norm: sum of absolute values.
    /// Most conservative - assumes worst-case linear accumulation.
    case l1

    /// L2 (Euclidean) norm: square root of sum of squares.
    /// Standard for uncorrelated Gaussian uncertainties.
    case l2

    /// Lp (generalized) norm with custom exponent.
    /// Interpolates between L1 (p=1) and L-infinity (p -> inf).
    case lp(p: Double)
}

// MARK: - Pure Norm Functions

/// Computes the L1 (Manhattan) norm of an array.
/// Formula: sum of |x_i|
public func norm1(_ xs: [Double]) -> Double {
    xs.reduce(0.0) { $0 + abs($1) }
}

/// Computes the L2 (Euclidean) norm of an array.
/// Uses hard coded for typical case of 3 or fewer values.
/// Uses numerically stable algorithm that scales by maximum value
/// to avoid overflow/underflow with extreme values.
public func norm2(_ xs: [Double]) -> Double {
    switch xs.count {
    case 0: return 0
    case 1: return abs(xs[0])
    case 2: return hypot(xs[0], xs[1])
    case 3: return hypot(hypot(xs[0], xs[1]), xs[2])
    default: // numerically stable because normalized between [0, 1]
        let m = xs.map { abs($0) }.max() ?? 0
        guard m > 0 else { return 0 }
        let s = xs.reduce(0.0) { acc, x in
            let t = abs(x) / m
            return acc + t * t
        }
        return m * sqrt(s)
    }
}

/// Computes the Lp norm of an array with given exponent.
/// Formula: (sum of |x_i|^p)^(1/p)
/// Uses numerically stable algorithm that scales by maximum value.
public func normp(_ xs: [Double], p: Double) -> Double {
    guard p > 0 else { return 0 }

    switch xs.count {
    case 0: return 0
    case 1: return abs(xs[0])
    default: // numerically stable because normalized between [0, 1]
        let m = xs.map { abs($0) }.max() ?? 0
        guard m > 0 else { return 0 }
        let s = xs.reduce(0.0) { acc, x in
            let t = abs(x) / m
            return acc + pow(t, p)
        }
        return m * pow(s, 1.0 / p)
    }
}

/// Computes the norm of an array using the specified strategy.
public func norm(_ xs: [Double], using strategy: NormStrategy) -> Double {
    switch strategy {
    case .l1:
        return norm1(xs)
    case .l2:
        return norm2(xs)
    case .lp(let p):
        return normp(xs, p: p)
    }
}
