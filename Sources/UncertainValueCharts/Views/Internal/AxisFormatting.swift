//
//  AxisFormatting.swift
//  BoundedValuesCharts
//
//  Axis label formatting helpers.
//

import Charts
import Foundation

enum AxisFormatting {
    static let axisNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: ChartConstants.AxisFormatting.localeIdentifier)
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = ChartConstants.AxisFormatting.maximumFractionDigits
        formatter.minimumFractionDigits = ChartConstants.AxisFormatting.minimumFractionDigits
        formatter.usesGroupingSeparator = ChartConstants.AxisFormatting.usesGroupingSeparator
        return formatter
    }()

    static func formattedAxisValue(_ value: AxisValue) -> String? {
        value.as(Double.self).flatMap { axisNumberFormatter.string(from: NSNumber(value: $0)) }
    }
}
