//
//  ChartViewport.swift
//  BoundedValuesCharts
//
//  Viewport model for chart pan/zoom.
//

import Foundation

public struct ChartViewport: Equatable, Sendable {
    public var xDomain: ClosedRange<Double>
    public var yDomain: ClosedRange<Double>

    public var xSpan: Double { xDomain.upperBound - xDomain.lowerBound }
    public var ySpan: Double { yDomain.upperBound - yDomain.lowerBound }

    public init(xDomain: ClosedRange<Double>, yDomain: ClosedRange<Double>) {
        self.xDomain = xDomain
        self.yDomain = yDomain
    }
}
