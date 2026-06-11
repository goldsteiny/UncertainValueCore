//
//  ChartAxisConfiguration.swift
//  BoundedValuesCharts
//
//  Axis configuration for labels, domains, and gridlines.
//

import Foundation

public struct ChartAxisConfiguration: Sendable, Equatable {
    public static let defaultGridLineCount: Int = ChartConstants.Axis.defaultGridLineCount

    public var label: String
    public var domain: ClosedRange<Double>?
    public var gridLineCount: Int
    public var scale: ChartAxisScale

    public init(
        label: String = "",
        domain: ClosedRange<Double>? = nil,
        gridLineCount: Int = ChartDefaults.Axis.gridLineCount,
        scale: ChartAxisScale = .linear
    ) {
        self.label = label
        self.domain = domain
        self.gridLineCount = gridLineCount
        self.scale = scale
    }

    public func withDomain(_ domain: ClosedRange<Double>?) -> ChartAxisConfiguration {
        var updated = self
        updated.domain = domain
        return updated
    }
}
