//
//  ChartViewportGestures.swift
//  BoundedValuesCharts
//
//  Pan and zoom gesture handling for chart viewports.
//

import CoreGraphics
import Foundation

enum ChartViewportGestures {
    static func panned(
        from start: ChartViewport,
        translation: CGSize,
        plotSize: CGSize,
        xScale: ChartAxisScale = .linear,
        yScale: ChartAxisScale = .linear
    ) -> ChartViewport {
        start.panned(translation: translation, plotSize: plotSize, xScale: xScale, yScale: yScale)
    }

    static func zoomed(
        from start: ChartViewport,
        magnification: CGFloat,
        minimumSpan: Double,
        xScale: ChartAxisScale = .linear,
        yScale: ChartAxisScale = .linear
    ) -> ChartViewport {
        start.zoomed(
            magnification: Double(magnification),
            minimumSpan: minimumSpan,
            xScale: xScale,
            yScale: yScale
        )
    }
}
