//
//  ChartAxisConfiguration.swift
//  BoundedValuesCharts
//
//  Axis configuration for labels, domains, and gridlines.
//

import Foundation

public struct ChartAxisConfiguration: Sendable, Equatable {
    public static let defaultGridLineCount: Int = 5

    public var label: String
    public var domain: ClosedRange<Double>?
    public var gridLineCount: Int

    public init(
        label: String = "",
        domain: ClosedRange<Double>? = nil,
        gridLineCount: Int = ChartAxisConfiguration.defaultGridLineCount
    ) {
        self.label = label
        self.domain = domain
        self.gridLineCount = gridLineCount
    }

    public func withDomain(_ domain: ClosedRange<Double>?) -> ChartAxisConfiguration {
        var updated = self
        updated.domain = domain
        return updated
    }
}
