//
//  ExportableChartView.swift
//  BoundedValuesCharts
//
//  High-resolution chart view for export.
//

import Charts
import SwiftUI

public struct ExportableChartView: View {
    public let config: ChartConfiguration

    public init(config: ChartConfiguration) {
        self.config = config
    }

    public var body: some View {
        let exportStyle = config.style.exportStyle

        VStack(alignment: .leading, spacing: exportStyle.verticalSpacing) {
            if !config.yAxis.label.isEmpty {
                Text(config.yAxis.label)
                    .font(.system(size: exportStyle.axisLabelFontSize, weight: .medium))
                    .foregroundColor(.black)
            }

            Chart { chartMarks(config: config, style: config.style.markStyles.export) }
                .applyChartDomains(xAxis: config.xAxis, yAxis: config.yAxis)
                .chartPlotStyle { $0.clipped() }
                .chartXAxis { exportXAxisMarks }
                .chartYAxis { exportYAxisMarks }
                .chartXAxisLabel {
                    Text(config.xAxis.label)
                        .font(.system(size: exportStyle.axisLabelFontSize, weight: .medium))
                        .foregroundColor(.black)
                }
                .chartLegend(.hidden)

            if config.shouldShowLegend {
                ChartLegendView(
                    series: config.series,
                    overlays: config.overlays,
                    markerSize: exportStyle.legendMarkerSize,
                    font: .system(size: exportStyle.legendFontSize),
                    foregroundColor: .black,
                    rowSpacing: exportStyle.legendRowSpacing,
                    itemSpacing: exportStyle.legendItemSpacing
                )
                .padding(.top, exportStyle.legendTopPadding)
            }
        }
        .padding(exportStyle.chartPadding)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }

    @AxisContentBuilder
    private var exportXAxisMarks: some AxisContent {
        AxisMarksBuilder.export(
            desiredCount: config.xAxis.gridLineCount,
            style: config.style.exportStyle
        )
    }

    @AxisContentBuilder
    private var exportYAxisMarks: some AxisContent {
        AxisMarksBuilder.export(
            desiredCount: config.yAxis.gridLineCount,
            position: .leading,
            style: config.style.exportStyle
        )
    }
}
