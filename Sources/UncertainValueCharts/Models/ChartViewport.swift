//
//  ChartViewport.swift
//  BoundedValuesCharts
//
//  Viewport model for chart pan/zoom.
//
//  Domains are always stored in data space. Pan, zoom, fit, and padding
//  math runs in axis-position space (see `ChartAxisScale`), so it stays
//  linear for any on-screen scale: panning a log axis shifts decades,
//  padding a log axis is multiplicative.
//

import CoreGraphics
import Foundation

public struct ChartViewport: Equatable, Sendable {
    public var xDomain: ClosedRange<Double>
    public var yDomain: ClosedRange<Double>

    public var xSpan: Double { xDomain.span }
    public var ySpan: Double { yDomain.span }

    public var xCenter: Double { xDomain.center }
    public var yCenter: Double { yDomain.center }

    public init(xDomain: ClosedRange<Double>, yDomain: ClosedRange<Double>) {
        self.xDomain = xDomain
        self.yDomain = yDomain
    }

    public init(centerX: Double, centerY: Double, xSpan: Double, ySpan: Double) {
        let xHalfSpan = xSpan / 2.0
        let yHalfSpan = ySpan / 2.0
        self.init(
            xDomain: (centerX - xHalfSpan)...(centerX + xHalfSpan),
            yDomain: (centerY - yHalfSpan)...(centerY + yHalfSpan)
        )
    }

    public func shifted(deltaX: Double, deltaY: Double) -> ChartViewport {
        ChartViewport(
            xDomain: (xDomain.lowerBound + deltaX)...(xDomain.upperBound + deltaX),
            yDomain: (yDomain.lowerBound + deltaY)...(yDomain.upperBound + deltaY)
        )
    }

    public func panned(
        translation: CGSize,
        plotSize: CGSize,
        xScale: ChartAxisScale = .linear,
        yScale: ChartAxisScale = .linear
    ) -> ChartViewport {
        guard plotSize.width > 0, plotSize.height > 0 else { return self }
        guard let xPositions = usablePositionRange(of: xDomain, scale: xScale),
              let yPositions = usablePositionRange(of: yDomain, scale: yScale) else { return self }

        let deltaX = -Double(translation.width / plotSize.width) * xPositions.span
        let deltaY = Double(translation.height / plotSize.height) * yPositions.span
        return ChartViewport(
            xDomain: xScale.domain(fromPositionRange: xPositions.shifted(by: deltaX)),
            yDomain: yScale.domain(fromPositionRange: yPositions.shifted(by: deltaY))
        )
    }

    public func zoomed(
        magnification: Double,
        minimumSpan: Double,
        xScale: ChartAxisScale = .linear,
        yScale: ChartAxisScale = .linear
    ) -> ChartViewport {
        guard magnification.isFinite, magnification > 0 else { return self }
        guard let xPositions = usablePositionRange(of: xDomain, scale: xScale),
              let yPositions = usablePositionRange(of: yDomain, scale: yScale) else { return self }

        return ChartViewport(
            xDomain: xScale.domain(fromPositionRange: xPositions.zoomed(by: magnification, minimumSpan: minimumSpan)),
            yDomain: yScale.domain(fromPositionRange: yPositions.zoomed(by: magnification, minimumSpan: minimumSpan))
        )
    }

    public static func fitToData(
        series: [ChartSeries],
        style: ChartStyle = .default,
        xScale: ChartAxisScale = .linear,
        yScale: ChartAxisScale = .linear
    ) -> ChartViewport? {
        guard let bounds = ChartDataBounds(series: series, xScale: xScale, yScale: yScale) else { return nil }

        guard let xDomain = bounds.xRange.padded(
            by: style.domainPaddingFraction,
            minimumSpan: style.minimumDomainSpan,
            scale: xScale
        ), let yDomain = bounds.yRange.padded(
            by: style.domainPaddingFraction,
            minimumSpan: style.minimumDomainSpan,
            scale: yScale
        ) else { return nil }

        return ChartViewport(xDomain: xDomain, yDomain: yDomain)
    }

    /// Position-space image of a domain, requiring a positive, finite span.
    private func usablePositionRange(
        of domain: ClosedRange<Double>,
        scale: ChartAxisScale
    ) -> ClosedRange<Double>? {
        guard let positions = scale.positionRange(of: domain),
              positions.span.isFinite, positions.span > 0 else { return nil }
        return positions
    }
}

private struct ChartDataBounds {
    let xRange: ClosedRange<Double>
    let yRange: ClosedRange<Double>

    init?(series: [ChartSeries], xScale: ChartAxisScale, yScale: ChartAxisScale) {
        let points = series.flatMap(\.points).filter { point in
            xScale.isRepresentable(point.x.value) && yScale.isRepresentable(point.y.value)
        }
        guard !points.isEmpty else { return nil }

        let xValues = points.flatMap { $0.x.finiteBoundsIncludingValue.filter(xScale.isRepresentable) }
        let yValues = points.flatMap { $0.y.finiteBoundsIncludingValue.filter(yScale.isRepresentable) }
        guard let xRange = xValues.range, let yRange = yValues.range else { return nil }
        guard xRange.isFiniteRange, yRange.isFiniteRange else { return nil }

        self.xRange = xRange
        self.yRange = yRange
    }
}

private extension ChartValue {
    var finiteBoundsIncludingValue: [Double] {
        [lowerBound, value, upperBound].filter(\.isFinite)
    }
}

private extension Collection where Element == Double {
    var range: ClosedRange<Double>? {
        guard let minValue = self.min(), let maxValue = self.max(), minValue <= maxValue else { return nil }
        return minValue...maxValue
    }
}

private extension ClosedRange where Bound == Double {
    var span: Double {
        upperBound - lowerBound
    }

    var center: Double {
        (lowerBound + upperBound) / 2.0
    }

    var isFiniteRange: Bool {
        lowerBound.isFinite && upperBound.isFinite
    }

    func shifted(by delta: Double) -> ClosedRange<Double> {
        (lowerBound + delta)...(upperBound + delta)
    }

    func zoomed(by magnification: Double, minimumSpan: Double) -> ClosedRange<Double> {
        let newHalfSpan = Swift.max(span / magnification, minimumSpan) / 2.0
        return (center - newHalfSpan)...(center + newHalfSpan)
    }

    /// Pads in position space: linear axes pad additively, log axes multiplicatively.
    func padded(by fraction: Double, minimumSpan: Double, scale: ChartAxisScale) -> ClosedRange<Double>? {
        guard let positions = scale.positionRange(of: self) else { return nil }
        let baseSpan = Swift.max(positions.span, minimumSpan)
        let halfSpan = baseSpan * (0.5 + fraction)
        return scale.domain(fromPositionRange: (positions.center - halfSpan)...(positions.center + halfSpan))
    }
}
