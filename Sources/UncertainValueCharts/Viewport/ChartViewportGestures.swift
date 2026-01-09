//
//  ChartViewportGestures.swift
//  BoundedValuesCharts
//
//  Pan and zoom gesture handling for chart viewports.
//

import CoreGraphics
import Foundation

enum ChartViewportGestures {
    static func panned(from start: ChartViewport, translation: CGSize, plotSize: CGSize) -> ChartViewport {
        guard plotSize.width > 0, plotSize.height > 0 else { return start }
        guard start.xSpan.isFinite, start.ySpan.isFinite, start.xSpan > 0, start.ySpan > 0 else { return start }

        let deltaX = -Double(translation.width / plotSize.width) * start.xSpan
        let deltaY = Double(translation.height / plotSize.height) * start.ySpan

        return ChartViewport(
            xDomain: (start.xDomain.lowerBound + deltaX)...(start.xDomain.upperBound + deltaX),
            yDomain: (start.yDomain.lowerBound + deltaY)...(start.yDomain.upperBound + deltaY)
        )
    }

    static func zoomed(from start: ChartViewport, magnification: CGFloat, minimumSpan: Double) -> ChartViewport {
        let m = Double(magnification)
        guard m.isFinite, m > 0 else { return start }
        guard start.xSpan.isFinite, start.ySpan.isFinite, start.xSpan > 0, start.ySpan > 0 else { return start }

        let newXSpan = max(start.xSpan / m, minimumSpan)
        let newYSpan = max(start.ySpan / m, minimumSpan)

        let xCenter = (start.xDomain.lowerBound + start.xDomain.upperBound) / 2.0
        let yCenter = (start.yDomain.lowerBound + start.yDomain.upperBound) / 2.0

        return ChartViewport(
            xDomain: (xCenter - newXSpan / 2.0)...(xCenter + newXSpan / 2.0),
            yDomain: (yCenter - newYSpan / 2.0)...(yCenter + newYSpan / 2.0)
        )
    }
}
