//
//  AxisFormatting.swift
//  BoundedValuesCharts
//
//  Axis label formatting helpers.
//

import Charts
import Foundation

enum AxisFormatting {
    static func formattedAxisValue(_ value: AxisValue) -> String? {
        value.as(Double.self).flatMap(formattedAxisValue)
    }

    static func formattedAxisValue(_ rawValue: Double) -> String? {
        ChartDefaults.AxisFormatting.numberFormatter.string(from: NSNumber(value: rawValue))
    }
}
