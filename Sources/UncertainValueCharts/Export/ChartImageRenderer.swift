//
//  ChartImageRenderer.swift
//  BoundedValuesCharts
//
//  Image export helper.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

public struct ChartImageRenderer {
    @MainActor
    public static func render(_ config: ChartConfiguration, size: CGSize) -> UIImage? {
        let exportView = ExportableChartView(config: config)
            .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = ChartDefaults.Export.imageScale

        return renderer.uiImage
    }
}
#endif
