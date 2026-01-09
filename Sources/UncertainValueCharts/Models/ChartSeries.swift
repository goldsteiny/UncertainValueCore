//
//  ChartSeries.swift
//  BoundedValuesCharts
//
//  Series model for chart rendering.
//

import Foundation

public struct ChartSeries: Identifiable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let label: String
    public let color: ChartColor
    public let points: [ChartPoint]

    public init(id: UUID = UUID(), label: String, color: ChartColor, points: [ChartPoint]) {
        self.id = id
        self.label = label
        self.color = color
        self.points = points
    }
}
