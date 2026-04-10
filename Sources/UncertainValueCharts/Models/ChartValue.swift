//
//  ChartValue.swift
//  BoundedValuesCharts
//
//  Chart-friendly alias for bounded values.
//

import Foundation
import UncertainValueSupport

public typealias ChartValue = BoundedDouble

public extension ChartValue {
    var hasErrorBounds: Bool {
        !isSinglePoint
    }
}
