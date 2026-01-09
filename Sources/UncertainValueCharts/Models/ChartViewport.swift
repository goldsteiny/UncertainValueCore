//
//  ChartViewport.swift
//  BoundedValuesCharts
//
//  Viewport model for chart pan/zoom.
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

    public func panned(translation: CGSize, plotSize: CGSize) -> ChartViewport {
        guard plotSize.width > 0, plotSize.height > 0 else { return self }
        guard xSpan.isFinite, ySpan.isFinite, xSpan > 0, ySpan > 0 else { return self }

        let deltaX = -Double(translation.width / plotSize.width) * xSpan
        let deltaY = Double(translation.height / plotSize.height) * ySpan
        return shifted(deltaX: deltaX, deltaY: deltaY)
    }

    public func zoomed(magnification: Double, minimumSpan: Double) -> ChartViewport {
        guard magnification.isFinite, magnification > 0 else { return self }
        guard xSpan.isFinite, ySpan.isFinite, xSpan > 0, ySpan > 0 else { return self }

        let newXSpan = max(xSpan / magnification, minimumSpan)
        let newYSpan = max(ySpan / magnification, minimumSpan)
        return ChartViewport(centerX: xCenter, centerY: yCenter, xSpan: newXSpan, ySpan: newYSpan)
    }

    public static func fitToData(series: [ChartSeries], style: ChartStyle = .default) -> ChartViewport? {
        guard let bounds = ChartDataBounds(series: series) else { return nil }

        let xDomain = bounds.xRange.padded(
            by: style.domainPaddingFraction,
            minimumSpan: style.minimumDomainSpan
        )
        let yDomain = bounds.yRange.padded(
            by: style.domainPaddingFraction,
            minimumSpan: style.minimumDomainSpan
        )

        return ChartViewport(xDomain: xDomain, yDomain: yDomain)
    }
}

private struct ChartDataBounds {
    let xRange: ClosedRange<Double>
    let yRange: ClosedRange<Double>

    init?(series: [ChartSeries]) {
        let points = series.flatMap(\.points)
        guard !points.isEmpty else { return nil }

        let xValues = points.map(\.x.value)
        let yValues = points.map(\.y.value)
        guard let xRange = xValues.range, let yRange = yValues.range else { return nil }
        guard xRange.isFiniteRange, yRange.isFiniteRange else { return nil }

        self.xRange = xRange
        self.yRange = yRange
    }
}

private extension Collection where Element == Double {
    var range: ClosedRange<Double>? {
        guard let minValue = self.min(), let maxValue = self.max() else { return nil }
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

    func padded(by fraction: Double, minimumSpan: Double) -> ClosedRange<Double> {
        let baseSpan = Swift.max(span, minimumSpan)
        let halfSpan = baseSpan * (0.5 + fraction)
        return (center - halfSpan)...(center + halfSpan)
    }
}
