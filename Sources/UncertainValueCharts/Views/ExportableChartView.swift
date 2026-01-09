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
            if !config.yAxisLabel.isEmpty {
                Text(config.yAxisLabel)
                    .font(.system(size: exportStyle.yAxisLabelFontSize, weight: .medium))
                    .foregroundColor(.black)
            }

            Chart { chartMarks(config: config, style: config.style.markStyles.export) }
                .applyChartDomains(xDomain: config.xDomain, yDomain: config.yDomain)
                .chartPlotStyle { $0.clipped() }
                .chartXAxis { exportXAxisMarks }
                .chartYAxis { exportYAxisMarks }
                .chartXAxisLabel {
                    Text(config.xAxisLabel)
                        .font(.system(size: exportStyle.xAxisLabelFontSize, weight: .medium))
                        .foregroundColor(.black)
                }
                .chartLegend(.hidden)

            if showLegend {
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

    private var showLegend: Bool {
        config.series.count > 1 || !config.overlays.isEmpty
    }

    @AxisContentBuilder
    private var exportXAxisMarks: some AxisContent {
        let exportStyle = config.style.exportStyle
        AxisMarks(values: .automatic(desiredCount: config.style.gridLineCount.vertical)) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: exportStyle.gridLineWidth))
                .foregroundStyle(Color.gray.opacity(exportStyle.gridLineOpacity))
            AxisTick(stroke: StrokeStyle(lineWidth: exportStyle.gridLineWidth))
            AxisValueLabel {
                Text(AxisFormatting.formattedAxisValue(value) ?? "")
                    .font(.system(size: exportStyle.axisValueFontSize))
                    .foregroundColor(.black)
            }
        }
    }

    @AxisContentBuilder
    private var exportYAxisMarks: some AxisContent {
        let exportStyle = config.style.exportStyle
        AxisMarks(position: .leading, values: .automatic(desiredCount: config.style.gridLineCount.horizontal)) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: exportStyle.gridLineWidth))
                .foregroundStyle(Color.gray.opacity(exportStyle.gridLineOpacity))
            AxisTick(stroke: StrokeStyle(lineWidth: exportStyle.gridLineWidth))
            AxisValueLabel {
                Text(AxisFormatting.formattedAxisValue(value) ?? "")
                    .font(.system(size: exportStyle.axisValueFontSize))
                    .foregroundColor(.black)
            }
        }
    }
}
