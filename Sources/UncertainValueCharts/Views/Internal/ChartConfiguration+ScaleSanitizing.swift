//
//  ChartConfiguration+ScaleSanitizing.swift
//  BoundedValuesCharts
//
//  Removes or clamps content that cannot be placed on the configured
//  axis scales before it reaches Swift Charts (which would otherwise
//  receive undefined positions, e.g. log of a non-positive value).
//

import CoreGraphics
import Foundation

extension ChartConfiguration {
    /// A configuration whose series, overlays, and bands contain only
    /// values representable on the configured axis scales. Points whose
    /// center value is unrepresentable are dropped; error bounds crossing
    /// into unrepresentable territory are clamped to the axis domain edge
    /// (the plot clips there anyway, matching the convention of drawing
    /// out-of-range error bars to the plot border).
    func sanitizedForScales() -> ChartConfiguration {
        guard xAxis.scale != .linear || yAxis.scale != .linear else { return self }
        var sanitized = self
        sanitized.xAxis = xAxis.withDomain(xAxis.domain.flatMap { xAxis.scale.renderableDomain(of: $0) })
        sanitized.yAxis = yAxis.withDomain(yAxis.domain.flatMap { yAxis.scale.renderableDomain(of: $0) })
        sanitized.series = series.map(sanitizedSeries)
        sanitized.overlays = overlays.compactMap(sanitizedOverlay)
        sanitized.overlayBands = overlayBands.compactMap(sanitizedBand)
        return sanitized
    }

    // MARK: - Series

    private func sanitizedSeries(_ series: ChartSeries) -> ChartSeries {
        ChartSeries(
            id: series.id,
            label: series.label,
            color: series.color,
            points: series.points.compactMap(sanitizedPoint)
        )
    }

    private func sanitizedPoint(_ point: ChartPoint) -> ChartPoint? {
        guard xAxis.scale.isRepresentable(point.x.value),
              yAxis.scale.isRepresentable(point.y.value) else { return nil }
        return ChartPoint(
            id: point.id,
            x: clampedValue(point.x, axis: xAxis),
            y: clampedValue(point.y, axis: yAxis)
        )
    }

    private func clampedValue(_ value: ChartValue, axis: ChartAxisConfiguration) -> ChartValue {
        guard axis.scale != .linear else { return value }
        return ChartValue(
            value: value.value,
            lowerBound: clampedBound(value.lowerBound, fallback: value.value, axis: axis),
            upperBound: clampedBound(value.upperBound, fallback: value.value, axis: axis)
        )
    }

    private func clampedBound(
        _ bound: Double,
        fallback: Double,
        axis: ChartAxisConfiguration
    ) -> Double {
        if axis.scale.isRepresentable(bound) { return bound }
        if let floor = axis.domain?.lowerBound, axis.scale.isRepresentable(floor) { return floor }
        return fallback
    }

    // MARK: - Overlay lines

    private func sanitizedOverlay(_ line: ChartOverlayLine) -> ChartOverlayLine? {
        let segments = line.segments.flatMap(sanitizedSegments)
        guard !segments.isEmpty else { return nil }
        return ChartOverlayLine(id: line.id, label: line.label, color: line.color, segments: segments)
    }

    private func sanitizedSegments(_ segment: ChartOverlaySegment) -> [ChartOverlaySegment] {
        let runs = segment.points.split { point in
            !xAxis.scale.isRepresentable(Double(point.x)) || !yAxis.scale.isRepresentable(Double(point.y))
        }
        if runs.count == 1, runs[0].count == segment.points.count {
            return [segment]
        }
        return runs
            .filter { $0.count >= 2 }
            .map { ChartOverlaySegment(points: Array($0)) }
    }

    // MARK: - Bands

    private func sanitizedBand(_ band: ChartOverlayBand) -> ChartOverlayBand? {
        guard xAxis.scale != .linear else { return band }
        guard xAxis.scale.isRepresentable(band.xRange.upperBound) else { return nil }

        let lower = clampedBound(
            band.xRange.lowerBound,
            fallback: band.xRange.upperBound,
            axis: xAxis
        )
        guard lower < band.xRange.upperBound else { return nil }
        return ChartOverlayBand(
            id: band.id,
            label: band.label,
            color: band.color,
            xRange: lower...band.xRange.upperBound,
            opacity: band.opacity
        )
    }
}
