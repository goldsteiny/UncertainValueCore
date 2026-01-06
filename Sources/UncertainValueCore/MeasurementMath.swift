//
//  MeasurementMath.swift
//  UncertainValueCore
//
//  Mathematical operations on UncertainValue with proper error propagation.
//

import Foundation
import Darwin

public enum MeasurementMath {
    // MARK: - Transcendental Functions

    /// Natural logarithm with error propagation.
    /// - Parameter uv: Input value (must be positive).
    /// - Returns: ln(x) with propagated error, or nil if x <= 0.
    /// - Formula: delta(ln(x)) = delta(x) / x = relError(x)
    public static func log(_ uv: UncertainValue) -> UncertainValue? {
        guard uv.value > 0 else { return nil }
        return UncertainValue(Darwin.log(uv.value), absoluteError: uv.relativeError)
    }

    /// Natural logarithm applied to array.
    public static func log(_ values: [UncertainValue]) -> [UncertainValue]? {
        let transformed = values.compactMap(log)
        return transformed.count == values.count ? transformed : nil
    }

    /// Exponential function with error propagation.
    /// - Parameter uv: Input value.
    /// - Returns: e^x with propagated error.
    /// - Formula: relError(e^x) = absoluteError(x)
    public static func exp(_ uv: UncertainValue) -> UncertainValue {
        UncertainValue.withRelativeError(Darwin.exp(uv.value), uv.absoluteError)
    }

    /// Exponential applied to array.
    public static func exp(_ values: [UncertainValue]) -> [UncertainValue] {
        values.map(exp)
    }

    /// Sine function with error propagation.
    /// - Parameter uv: Input value in radians.
    /// - Returns: sin(x) with propagated error.
    /// - Formula: delta(sin(x)) = |cos(x)| * delta(x)
    public static func sin(_ uv: UncertainValue) -> UncertainValue {
        let newValue = Darwin.sin(uv.value)
        // Error propagation: δ(sin(x)) = |cos(x)| * δx
        let newAbsError = abs(Darwin.cos(uv.value)) * uv.absoluteError
        return UncertainValue(newValue, absoluteError: newAbsError)
    }

    /// Cosine function with error propagation.
    /// - Parameter uv: Input value in radians.
    /// - Returns: cos(x) with propagated error.
    /// - Formula: delta(cos(x)) = |sin(x)| * delta(x)
    public static func cos(_ uv: UncertainValue) -> UncertainValue {
        let newValue = Darwin.cos(uv.value)
        // Error propagation: δ(cos(x)) = |sin(x)| * δx
        let newAbsError = abs(Darwin.sin(uv.value)) * uv.absoluteError
        return UncertainValue(newValue, absoluteError: newAbsError)
    }

    /// Reciprocal (1/x) with error propagation.
    public static func reciprocal(_ uv: UncertainValue) -> UncertainValue? {
        uv.reciprocalOrNil
    }

    // MARK: - Multi-Input Functions (require norm strategy)

    /// Sigmoid/logistic function: sigma(x, x0, k) = 1 / (1 + exp(-k*(x-x0)))
    /// - Parameters:
    ///   - x: Input value.
    ///   - x0: Midpoint (inflection point).
    ///   - k: Steepness parameter.
    ///   - strategy: Norm strategy for combining errors.
    /// - Returns: Value in range (0, 1) with proper error propagation.
    public static func sigmoid(
        _ x: UncertainValue,
        _ x0: UncertainValue,
        _ k: UncertainValue,
        using strategy: NormStrategy
    ) -> UncertainValue {
        let diff = x.value - x0.value
        let exponent = -k.value * diff
        let expTerm = Darwin.exp(exponent)
        let sigma = 1.0 / (1.0 + expTerm)

        // Error propagation: delta(sigma) = sigma*(1-sigma) * norm((k*delta_x), (k*delta_x0), ((x-x0)*delta_k))
        let sigmaPrime = sigma * (1.0 - sigma)
        let errorContributions = [
            k.value * x.absoluteError,
            k.value * x0.absoluteError,
            diff * k.absoluteError
        ]
        let combinedError = norm(errorContributions, using: strategy)
        let absoluteError = sigmaPrime * combinedError

        return UncertainValue(sigma, absoluteError: absoluteError)
    }

    /// Lorentz-factor-like transformation: f(x, y) = 1/sqrt(1-(x/y)^2)
    /// - Parameters:
    ///   - x: Numerator value.
    ///   - y: Denominator value.
    ///   - strategy: Norm strategy for combining errors.
    /// - Returns: Transformation result with error propagation, or nil if invalid.
    public static func lorentzFactor(
        _ x: UncertainValue,
        _ y: UncertainValue,
        using strategy: NormStrategy
    ) -> UncertainValue? {
        guard y.absoluteValue > 0 else { return nil }

        let ratio = x.value / y.value
        let ratioSquared = ratio * ratio

        guard ratioSquared < 1.0 else { return nil }

        let discriminant = 1.0 - ratioSquared
        let f = 1.0 / Darwin.sqrt(discriminant)

        // Error propagation: delta(f) = f^3 * (x/y)^2 * norm(relError(x), relError(y))
        let f3 = f * f * f
        let relErrorCombined = [x, y].relativeErrorVectorLength(using: strategy)
        let absoluteError = f3 * ratioSquared * relErrorCombined

        return UncertainValue(f, absoluteError: absoluteError)
    }

    /// Polynomial evaluation: P(x) = a0 + a1*x + a2*x^2 + ... + an*x^n
    /// - Parameters:
    ///   - coefficients: Vector of polynomial coefficients [a0, a1, a2, ...].
    ///   - x: Input value.
    ///   - strategy: Norm strategy for combining errors in the sum.
    /// - Returns: Polynomial evaluation with proper error propagation.
    public static func polynomial(
        _ coefficients: [UncertainValue],
        _ x: UncertainValue,
        using strategy: NormStrategy
    ) -> UncertainValue? {
        guard !coefficients.isEmpty else { return nil }

        let terms = coefficients.enumerated().compactMap { (i, a) -> UncertainValue? in
            if i == 0 {
                return a
            } else {
                return x.raised(to: i)?.multiplying(a, using: strategy)
            }
        }

        guard terms.count == coefficients.count else { return nil }
        return terms.sum(using: strategy)
    }

    // MARK: - Normalization

    /// Divides all value by denominator using the specified norm strategy.
    /// - Parameters:
    ///   - values: Values to normalize.
    ///   - denominator: Divisor value.
    ///   - strategy: Norm strategy for combining relative errors.
    public static func normalize(
        _ values: [UncertainValue],
        by denominator: UncertainValue,
        using strategy: NormStrategy
    ) -> [UncertainValue]? {
        let normalized = values.compactMap { $0.dividingOrNil(by: denominator, using: strategy) }
        return normalized.count == values.count ? normalized : nil
    }

    /// Normalizes array by its first element (first element becomes 1.0 with zero error).
    public static func normalizeByFirst(
        _ values: [UncertainValue],
        using strategy: NormStrategy
    ) -> [UncertainValue]? {
        guard let first = values.first else { return nil }
        guard var normalized = normalize(values, by: first, using: strategy) else { return nil }
        normalized[0] = UncertainValue(1.0, absoluteError: 0.0)
        return normalized
    }

    /// Average step width between consecutive values using the specified norm strategy.
    public static func averageStepWidth(
        _ values: [UncertainValue],
        using strategy: NormStrategy
    ) -> UncertainValue? {
        guard values.count > 1, let first = values.first, let last = values.last else {
            return nil
        }
        return last.subtracting(first, using: strategy).dividing(by: Double(values.count - 1))
    }
}
