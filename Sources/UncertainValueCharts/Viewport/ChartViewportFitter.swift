//
//  ChartViewportFitter.swift
//  BoundedValuesCharts
//
//  Auto-fit logic for chart viewport.
//

import Foundation

private struct PointsSummary {
    let hasAnyPoint: Bool
    let minX: Double
    let maxX: Double
    let minY: Double
    let maxY: Double

    static var noPointsSummary: PointsSummary {
        PointsSummary(
            hasAnyPoint: false,
            minX: Double.greatestFiniteMagnitude,
            maxX: -Double.greatestFiniteMagnitude,
            minY: Double.greatestFiniteMagnitude,
            maxY: -Double.greatestFiniteMagnitude
        )
    }

    func updated(with newPoint: ChartPoint) -> PointsSummary {
        PointsSummary(
            hasAnyPoint: true,
            minX: min(minX, newPoint.x.value),
            maxX: max(maxX, newPoint.x.value),
            minY: min(minY, newPoint.y.value),
            maxY: max(maxY, newPoint.y.value)
        )
    }

    var isBounded: Bool {
        minX.isFinite && maxX.isFinite && minY.isFinite && maxY.isFinite
    }

    var xSpan: Double { maxX - minX }
    var ySpan: Double { maxY - minY }
    var xCenter: Double { 0.5 * (minX + maxX) }
    var yCenter: Double { 0.5 * (minY + maxY) }
}

public enum ChartViewportFitter {
    public static func fitToData(series: [ChartSeries], style: ChartStyle = .default) -> ChartViewport? {
        let allPoints = series.flatMap(\.points)
        let pointsDescription = allPoints.reduce(PointsSummary.noPointsSummary) { result, point in
            result.updated(with: point)
        }

        guard pointsDescription.hasAnyPoint, pointsDescription.isBounded else {
            return nil
        }

        let padFraction = style.domainPaddingFraction
        let baseXSpan = max(pointsDescription.xSpan, style.minimumDomainSpan)
        let baseYSpan = max(pointsDescription.ySpan, style.minimumDomainSpan)

        let xHalfSpan = baseXSpan * (0.5 + padFraction)
        let yHalfSpan = baseYSpan * (0.5 + padFraction)

        let x = pointsDescription.xCenter
        let y = pointsDescription.yCenter
        return ChartViewport(
            xDomain: (x - xHalfSpan)...(x + xHalfSpan),
            yDomain: (y - yHalfSpan)...(y + yHalfSpan)
        )
    }
}
