//
//  View+ChartDomains.swift
//  BoundedValuesCharts
//
//  Shared chart view helpers.
//

import Charts
import SwiftUI

extension View {
    func applyChartDomains(xAxis: ChartAxisConfiguration, yAxis: ChartAxisConfiguration) -> some View {
        applyXAxisScale(xAxis).applyYAxisScale(yAxis)
    }

    @ViewBuilder
    private func applyXAxisScale(_ axis: ChartAxisConfiguration) -> some View {
        switch (axis.renderableDomain, axis.scale.scaleType) {
        case let (domain?, type?):
            self.chartXScale(domain: domain, type: type)
        case let (domain?, nil):
            self.chartXScale(domain: domain)
        case let (nil, type?):
            self.chartXScale(type: type)
        case (nil, nil):
            self
        }
    }

    @ViewBuilder
    private func applyYAxisScale(_ axis: ChartAxisConfiguration) -> some View {
        switch (axis.renderableDomain, axis.scale.scaleType) {
        case let (domain?, type?):
            self.chartYScale(domain: domain, type: type)
        case let (domain?, nil):
            self.chartYScale(domain: domain)
        case let (nil, type?):
            self.chartYScale(type: type)
        case (nil, nil):
            self
        }
    }
}

private extension ChartAxisConfiguration {
    var renderableDomain: ClosedRange<Double>? {
        domain.flatMap { scale.renderableDomain(of: $0) }
    }
}

private extension ChartAxisScale {
    /// The Swift Charts scale type, or nil to keep the framework default (linear).
    var scaleType: ScaleType? {
        switch self {
        case .linear: return nil
        case .log10: return .log
        }
    }
}
