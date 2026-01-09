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
        value.as(Double.self).flatMap { ChartDefaults.AxisFormatting.numberFormatter.string(from: NSNumber(value: $0)) }
    }
}
