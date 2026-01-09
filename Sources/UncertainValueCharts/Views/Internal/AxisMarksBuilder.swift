//
//  AxisMarksBuilder.swift
//  BoundedValuesCharts
//
//  Shared axis mark builders for interactive and export charts.
//

import Charts
import SwiftUI

enum AxisMarksBuilder {
    @AxisContentBuilder
    static func interactive(desiredCount: Int, position: AxisMarkPosition? = nil) -> some AxisContent {
        if let position {
            AxisMarks(position: position, values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel { Text(AxisFormatting.formattedAxisValue(value) ?? "") }
            }
        } else {
            AxisMarks(values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel { Text(AxisFormatting.formattedAxisValue(value) ?? "") }
            }
        }
    }

    @AxisContentBuilder
    static func export(
        desiredCount: Int,
        position: AxisMarkPosition? = nil,
        style: ChartStyle.ExportStyle
    ) -> some AxisContent {
        if let position {
            AxisMarks(position: position, values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: style.gridLineWidth))
                    .foregroundStyle(Color.gray.opacity(style.gridLineOpacity))
                AxisTick(stroke: StrokeStyle(lineWidth: style.gridLineWidth))
                AxisValueLabel {
                    Text(AxisFormatting.formattedAxisValue(value) ?? "")
                        .font(.system(size: style.axisValueFontSize))
                        .foregroundColor(.black)
                }
            }
        } else {
            AxisMarks(values: .automatic(desiredCount: desiredCount)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: style.gridLineWidth))
                    .foregroundStyle(Color.gray.opacity(style.gridLineOpacity))
                AxisTick(stroke: StrokeStyle(lineWidth: style.gridLineWidth))
                AxisValueLabel {
                    Text(AxisFormatting.formattedAxisValue(value) ?? "")
                        .font(.system(size: style.axisValueFontSize))
                        .foregroundColor(.black)
                }
            }
        }
    }
}
