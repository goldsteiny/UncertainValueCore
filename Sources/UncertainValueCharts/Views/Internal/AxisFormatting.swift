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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static func formattedAxisValue(_ value: AxisValue) -> String? {
        value.as(Double.self).flatMap { axisNumberFormatter.string(from: NSNumber(value: $0)) }
    }
}
