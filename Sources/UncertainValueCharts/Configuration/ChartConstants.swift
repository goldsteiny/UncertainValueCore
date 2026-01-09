//
//  ChartConstants.swift
//  BoundedValuesCharts
//
//  Centralized defaults and formatting constants for chart rendering.
//

import CoreGraphics
import Foundation

enum ChartConstants {
    enum Axis {
        static let defaultGridLineCount: Int = 5
    }

    enum AxisFormatting {
        static let localeIdentifier: String = "en_US_POSIX"
        static let maximumFractionDigits: Int = 6
        static let minimumFractionDigits: Int = 0
        static let usesGroupingSeparator: Bool = false
    }

    enum Gestures {
        static let defaultMagnification: CGFloat = 1.0
        static let doubleTapCount: Int = 2
    }

    enum Export {
        static let imageScale: CGFloat = 1.0
    }

    enum LegendLayout {
        static let lineWidthMultiplier: CGFloat = 2
        static let minimumLineHeight: CGFloat = 2
        static let lineHeightDivisor: CGFloat = 3
        static let minimumSeriesCountForLegend: Int = 2
    }

    enum StyleDefaults {
        static let domainPaddingFraction: Double = 0.05
        static let minimumDomainSpan: Double = 1e-12
        static let interactiveVerticalSpacing: CGFloat = 12

        enum Mark {
            static let interactivePointSymbolSize: CGFloat? = nil
            static let interactiveErrorLineWidth: CGFloat = 1.5
            static let interactiveErrorOpacity: Double = 0.7
            static let interactiveOverlayLineWidth: CGFloat = 2

            static let exportPointSymbolSize: CGFloat? = 150
            static let exportErrorLineWidth: CGFloat = 2.5
            static let exportErrorOpacity: Double = 0.8
            static let exportOverlayLineWidth: CGFloat = 3
        }

        enum Legend {
            static let markerSize: CGFloat = 8
            static let rowSpacing: CGFloat = 16
            static let itemSpacing: CGFloat = 4
        }

        enum Export {
            static let verticalSpacing: CGFloat = 24
            static let axisLabelFontSize: CGFloat = 26
            static let axisValueFontSize: CGFloat = 22
            static let gridLineWidth: CGFloat = 1
            static let gridLineOpacity: Double = 0.4
            static let legendMarkerSize: CGFloat = 16
            static let legendFontSize: CGFloat = 24
            static let legendRowSpacing: CGFloat = 32
            static let legendItemSpacing: CGFloat = 10
            static let legendTopPadding: CGFloat = 8
            static let chartPadding: CGFloat = 60
        }
    }
}
