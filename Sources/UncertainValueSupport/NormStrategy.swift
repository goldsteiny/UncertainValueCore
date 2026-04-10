//
//  NormStrategy.swift
//  UncertainValueSupport
//
//  Norm definitions used for uncertainty propagation.
//

import Foundation

public enum NormStrategy: Hashable, Sendable {
    case l1
    case l2
    case lp(p: Double)
}

@inlinable
public func norm1(_ xs: [Double]) -> Double {
    xs.reduce(0.0) { $0 + abs($1) }
}

@inlinable
public func norm2(_ xs: [Double]) -> Double {
    switch xs.count {
    case 0:
        return 0.0
    case 1:
        return abs(xs[0])
    case 2:
        return hypot(xs[0], xs[1])
    case 3:
        return hypot(hypot(xs[0], xs[1]), xs[2])
    default:
        let maxAbsValue = xs.map { abs($0) }.max() ?? 0.0
        guard maxAbsValue > 0 else { return 0.0 }

        let normalizedSquares = xs.reduce(0.0) { partial, x in
            let scaled = abs(x) / maxAbsValue
            return partial + scaled * scaled
        }
        return maxAbsValue * sqrt(normalizedSquares)
    }
}

@inlinable
public func normp(_ xs: [Double], p: Double) -> Double {
    guard p > 0 else { return 0.0 }

    switch xs.count {
    case 0:
        return 0.0
    case 1:
        return abs(xs[0])
    default:
        let maxAbsValue = xs.map { abs($0) }.max() ?? 0.0
        guard maxAbsValue > 0 else { return 0.0 }

        let normalizedPowers = xs.reduce(0.0) { partial, x in
            let scaled = abs(x) / maxAbsValue
            return partial + pow(scaled, p)
        }
        return maxAbsValue * pow(normalizedPowers, 1.0 / p)
    }
}

@inlinable
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
