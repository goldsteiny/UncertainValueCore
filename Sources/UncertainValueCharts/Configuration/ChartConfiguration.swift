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
    public var xAxisLabel: String
    public var yAxisLabel: String
    public var xDomain: ClosedRange<Double>?
    public var yDomain: ClosedRange<Double>?
    public var style: ChartStyle

    public init(
        series: [ChartSeries],
        overlays: [ChartOverlayLine] = [],
        xAxisLabel: String = "",
        yAxisLabel: String = "",
        xDomain: ClosedRange<Double>? = nil,
        yDomain: ClosedRange<Double>? = nil,
        style: ChartStyle = .default
    ) {
        self.series = series
        self.overlays = overlays
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
        self.xDomain = xDomain
        self.yDomain = yDomain
        self.style = style
    }
}
