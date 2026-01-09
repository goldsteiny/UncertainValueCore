//
//  ChartPoint.swift
//  BoundedValuesCharts
//
//  Data point for chart series.
//

import Foundation

public struct ChartPoint: Identifiable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let x: ChartValue
    public let y: ChartValue

    public init(id: UUID = UUID(), x: ChartValue, y: ChartValue) {
        self.id = id
        self.x = x
        self.y = y
    }
}
