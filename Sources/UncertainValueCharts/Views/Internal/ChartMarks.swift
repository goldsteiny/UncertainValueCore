//
//  ChartMarks.swift
//  BoundedValuesCharts
//
//  Chart mark builders for points and overlays.
//

import Charts
import SwiftUI

struct SeriesPoint: Identifiable {
    let id: UUID
    let point: ChartPoint
    let color: Color

    init(point: ChartPoint, color: Color) {
        self.id = point.id
        self.point = point
        self.color = color
    }
}

private struct OverlayPoint: Identifiable {
    let id: Int
    let point: CGPoint
}

@ChartContentBuilder
func chartMarks(config: ChartConfiguration, style: ChartStyle.MarkStyle) -> some ChartContent {
    overlayLineMarks(from: config.overlays, lineWidth: style.overlayLineWidth)
    seriesMarks(from: config.series, style: style)
}

@ChartContentBuilder
private func seriesMarks(from series: [ChartSeries], style: ChartStyle.MarkStyle) -> some ChartContent {
    let points = series.flatMap { item in
        item.points.map { SeriesPoint(point: $0, color: item.color.swiftUIColor) }
    }
    ForEach(points) { item in
        pointMarks(item, style: style)
    }
}

@ChartContentBuilder
private func pointMarks(_ item: SeriesPoint, style: ChartStyle.MarkStyle) -> some ChartContent {
    let point = item.point
    let color = item.color

    if let symbolSize = style.pointSymbolSize {
        PointMark(x: .value("X", point.x.value), y: .value("Y", point.y.value))
            .foregroundStyle(color)
            .symbol(.circle)
            .symbolSize(symbolSize)
    } else {
        PointMark(x: .value("X", point.x.value), y: .value("Y", point.y.value))
            .foregroundStyle(color)
            .symbol(.circle)
    }

    if !point.y.isSinglePoint {
        RuleMark(
            x: .value("X", point.x.value),
            yStart: .value("Y Min", point.y.lowerBound),
            yEnd: .value("Y Max", point.y.upperBound)
        )
        .foregroundStyle(color.opacity(style.errorOpacity))
        .lineStyle(StrokeStyle(lineWidth: style.errorLineWidth))
    }

    if !point.x.isSinglePoint {
        RuleMark(
            xStart: .value("X Min", point.x.lowerBound),
            xEnd: .value("X Max", point.x.upperBound),
            y: .value("Y", point.y.value)
        )
        .foregroundStyle(color.opacity(style.errorOpacity))
        .lineStyle(StrokeStyle(lineWidth: style.errorLineWidth))
    }
}

@ChartContentBuilder
private func overlayLineMarks(from overlayLines: [ChartOverlayLine], lineWidth: CGFloat) -> some ChartContent {
    ForEach(overlayLines) { line in
        overlayMarks(for: line, lineWidth: lineWidth)
    }
}

@ChartContentBuilder
private func overlayMarks(for line: ChartOverlayLine, lineWidth: CGFloat) -> some ChartContent {
    let lineColor = line.color.swiftUIColor
    ForEach(line.segments) { segment in
        overlaySegmentMarks(segment, lineColor: lineColor, lineWidth: lineWidth)
    }
}

@ChartContentBuilder
private func overlaySegmentMarks(
    _ segment: ChartOverlaySegment,
    lineColor: Color,
    lineWidth: CGFloat
) -> some ChartContent {
    let points = segment.points.enumerated().map { OverlayPoint(id: $0.offset, point: $0.element) }
    ForEach(points) { item in
        let point = item.point
        LineMark(
            x: .value("X", Double(point.x)),
            y: .value("Y", Double(point.y)),
            series: .value("OverlaySegment", segment.id.uuidString)
        )
        .foregroundStyle(lineColor)
        .lineStyle(StrokeStyle(lineWidth: lineWidth))
        .interpolationMethod(.linear)
    }
}
