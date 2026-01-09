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
        start.panned(translation: translation, plotSize: plotSize)
    }

    static func zoomed(from start: ChartViewport, magnification: CGFloat, minimumSpan: Double) -> ChartViewport {
        start.zoomed(magnification: Double(magnification), minimumSpan: minimumSpan)
    }
}
