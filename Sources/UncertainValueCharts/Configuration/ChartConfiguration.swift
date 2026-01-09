//
//  ChartConfiguration.swift
//  BoundedValuesCharts
//
//  Public configuration for chart rendering.
//

import Foundation

public struct ChartConfiguration: Sendable, Equatable {
    public var series: [ChartSeries]
    public var overlays: [ChartOverlayLine]
    public var xAxis: ChartAxisConfiguration
    public var yAxis: ChartAxisConfiguration
    public var style: ChartStyle

    public init(
        series: [ChartSeries],
        overlays: [ChartOverlayLine] = [],
        xAxis: ChartAxisConfiguration = ChartAxisConfiguration(),
        yAxis: ChartAxisConfiguration = ChartAxisConfiguration(),
        style: ChartStyle = .default
    ) {
        self.series = series
        self.overlays = overlays
        self.xAxis = xAxis
        self.yAxis = yAxis
        self.style = style
    }

    public var shouldShowLegend: Bool {
        series.count >= ChartConstants.LegendLayout.minimumSeriesCountForLegend || !overlays.isEmpty
    }

    public func applying(viewport: ChartViewport?) -> ChartConfiguration {
        guard let viewport else { return self }
        var updated = self
        updated.xAxis = xAxis.withDomain(viewport.xDomain)
        updated.yAxis = yAxis.withDomain(viewport.yDomain)
        return updated
    }
}
