//
//  ChartOverlayLine.swift
//  BoundedValuesCharts
//
//  Overlay line data for chart rendering.
//

import CoreGraphics
import Foundation

public struct ChartOverlaySegment: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let points: [CGPoint]

    public init(id: UUID = UUID(), points: [CGPoint]) {
        self.id = id
        self.points = points
    }
}

public struct ChartOverlayLine: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let label: String
    public let color: ChartColor
    public let segments: [ChartOverlaySegment]

    public init(id: UUID = UUID(), label: String, color: ChartColor, segments: [ChartOverlaySegment]) {
        self.id = id
        self.label = label
        self.color = color
        self.segments = segments
    }
}
