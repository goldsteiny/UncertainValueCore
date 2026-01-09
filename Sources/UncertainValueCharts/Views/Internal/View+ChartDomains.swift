//
//  View+ChartDomains.swift
//  BoundedValuesCharts
//
//  Shared chart view helpers.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyChartDomains(xAxis: ChartAxisConfiguration, yAxis: ChartAxisConfiguration) -> some View {
        switch (xAxis.domain, yAxis.domain) {
        case let (x?, y?):
            self.chartXScale(domain: x).chartYScale(domain: y)
        case let (x?, nil):
            self.chartXScale(domain: x)
        case let (nil, y?):
            self.chartYScale(domain: y)
        case (nil, nil):
            self
        }
    }
}
