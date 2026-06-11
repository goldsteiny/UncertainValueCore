//
//  ChartAxisScale.swift
//  BoundedValuesCharts
//
//  How data values map to positions along one chart axis.
//
//  `position(of:)` and `value(atPosition:)` form the bijection between
//  data space and the axis's linear "position space". Viewport pan/zoom,
//  fit-to-data, and coordinate transforms run in position space, which
//  keeps their math linear regardless of the on-screen scale.
//

import Foundation

public enum ChartAxisScale: String, Codable, Hashable, CaseIterable, Sendable {
    case linear
    case log10

    /// True iff the value can be placed on this scale.
    public func isRepresentable(_ value: Double) -> Bool {
        switch self {
        case .linear: return value.isFinite
        case .log10: return value.isFinite && value > 0
        }
    }

    /// The axis position of a data value, or nil if not representable.
    public func position(of value: Double) -> Double? {
        guard isRepresentable(value) else { return nil }
        switch self {
        case .linear: return value
        case .log10: return Foundation.log10(value)
        }
    }

    /// The data value at an axis position. Inverse of `position(of:)`.
    public func value(atPosition position: Double) -> Double {
        switch self {
        case .linear: return position
        case .log10: return Foundation.pow(10.0, position)
        }
    }

    /// The position-space image of a data-space domain, or nil if either
    /// bound is not representable. Degenerate (zero-span) ranges are allowed.
    public func positionRange(of domain: ClosedRange<Double>) -> ClosedRange<Double>? {
        guard let lower = position(of: domain.lowerBound),
              let upper = position(of: domain.upperBound),
              lower <= upper else { return nil }
        return lower...upper
    }

    /// The data-space domain covering a position-space range.
    public func domain(fromPositionRange range: ClosedRange<Double>) -> ClosedRange<Double> {
        value(atPosition: range.lowerBound)...value(atPosition: range.upperBound)
    }

    /// The largest subrange of `domain` that can be shown on this scale.
    /// A log axis drops fully non-positive domains and truncates a
    /// non-positive lower bound to a fallback span of
    /// `ChartConstants.Scale.fallbackDecadeSpan` decades below the upper bound.
    public func renderableDomain(of domain: ClosedRange<Double>) -> ClosedRange<Double>? {
        switch self {
        case .linear:
            return domain
        case .log10:
            guard domain.upperBound > 0, domain.upperBound.isFinite else { return nil }
            guard domain.lowerBound > 0 else {
                let fallbackLower = domain.upperBound / Foundation.pow(10.0, ChartConstants.Scale.fallbackDecadeSpan)
                return fallbackLower...domain.upperBound
            }
            return domain
        }
    }
}
