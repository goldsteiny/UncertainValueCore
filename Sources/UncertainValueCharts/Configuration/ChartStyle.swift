//
//  ChartStyle.swift
//  BoundedValuesCharts
//
//  Style constants for chart rendering.
//

import CoreGraphics
import Foundation

public struct ChartStyle: Sendable, Equatable {
    public struct GridLineCount: Sendable, Equatable {
        public var horizontal: Int
        public var vertical: Int

        public init(horizontal: Int, vertical: Int) {
            self.horizontal = horizontal
            self.vertical = vertical
        }
    }

    public struct MarkStyle: Sendable, Equatable {
        public var pointSymbolSize: CGFloat?
        public var errorLineWidth: CGFloat
        public var errorOpacity: Double
        public var overlayLineWidth: CGFloat

        public init(
            pointSymbolSize: CGFloat?,
            errorLineWidth: CGFloat,
            errorOpacity: Double,
            overlayLineWidth: CGFloat
        ) {
            self.pointSymbolSize = pointSymbolSize
            self.errorLineWidth = errorLineWidth
            self.errorOpacity = errorOpacity
            self.overlayLineWidth = overlayLineWidth
        }
    }

    public struct MarkStyles: Sendable, Equatable {
        public var interactive: MarkStyle
        public var export: MarkStyle

        public init(interactive: MarkStyle, export: MarkStyle) {
            self.interactive = interactive
            self.export = export
        }
    }

    public struct LegendStyle: Sendable, Equatable {
        public var markerSize: CGFloat
        public var rowSpacing: CGFloat
        public var itemSpacing: CGFloat

        public init(markerSize: CGFloat, rowSpacing: CGFloat, itemSpacing: CGFloat) {
            self.markerSize = markerSize
            self.rowSpacing = rowSpacing
            self.itemSpacing = itemSpacing
        }
    }

    public struct ExportStyle: Sendable, Equatable {
        public var verticalSpacing: CGFloat
        public var yAxisLabelFontSize: CGFloat
        public var axisValueFontSize: CGFloat
        public var xAxisLabelFontSize: CGFloat
        public var gridLineWidth: CGFloat
        public var gridLineOpacity: Double
        public var legendMarkerSize: CGFloat
        public var legendFontSize: CGFloat
        public var legendRowSpacing: CGFloat
        public var legendItemSpacing: CGFloat
        public var legendTopPadding: CGFloat
        public var chartPadding: CGFloat

        public init(
            verticalSpacing: CGFloat,
            yAxisLabelFontSize: CGFloat,
            axisValueFontSize: CGFloat,
            xAxisLabelFontSize: CGFloat,
            gridLineWidth: CGFloat,
            gridLineOpacity: Double,
            legendMarkerSize: CGFloat,
            legendFontSize: CGFloat,
            legendRowSpacing: CGFloat,
            legendItemSpacing: CGFloat,
            legendTopPadding: CGFloat,
            chartPadding: CGFloat
        ) {
            self.verticalSpacing = verticalSpacing
            self.yAxisLabelFontSize = yAxisLabelFontSize
            self.axisValueFontSize = axisValueFontSize
            self.xAxisLabelFontSize = xAxisLabelFontSize
            self.gridLineWidth = gridLineWidth
            self.gridLineOpacity = gridLineOpacity
            self.legendMarkerSize = legendMarkerSize
            self.legendFontSize = legendFontSize
            self.legendRowSpacing = legendRowSpacing
            self.legendItemSpacing = legendItemSpacing
            self.legendTopPadding = legendTopPadding
            self.chartPadding = chartPadding
        }
    }

    public var gridLineCount: GridLineCount
    public var domainPaddingFraction: Double
    public var minimumDomainSpan: Double
    public var markStyles: MarkStyles
    public var legendStyle: LegendStyle
    public var exportStyle: ExportStyle
    public var interactiveVerticalSpacing: CGFloat

    public init(
        gridLineCount: GridLineCount,
        domainPaddingFraction: Double,
        minimumDomainSpan: Double,
        markStyles: MarkStyles,
        legendStyle: LegendStyle,
        exportStyle: ExportStyle,
        interactiveVerticalSpacing: CGFloat
    ) {
        self.gridLineCount = gridLineCount
        self.domainPaddingFraction = domainPaddingFraction
        self.minimumDomainSpan = minimumDomainSpan
        self.markStyles = markStyles
        self.legendStyle = legendStyle
        self.exportStyle = exportStyle
        self.interactiveVerticalSpacing = interactiveVerticalSpacing
    }

    public static let `default` = ChartStyle(
        gridLineCount: GridLineCount(horizontal: 5, vertical: 5),
        domainPaddingFraction: 0.05,
        minimumDomainSpan: 1e-12,
        markStyles: MarkStyles(
            interactive: MarkStyle(
                pointSymbolSize: nil,
                errorLineWidth: 1.5,
                errorOpacity: 0.7,
                overlayLineWidth: 2
            ),
            export: MarkStyle(
                pointSymbolSize: 150,
                errorLineWidth: 2.5,
                errorOpacity: 0.8,
                overlayLineWidth: 3
            )
        ),
        legendStyle: LegendStyle(
            markerSize: 8,
            rowSpacing: 16,
            itemSpacing: 4
        ),
        exportStyle: ExportStyle(
            verticalSpacing: 24,
            yAxisLabelFontSize: 28,
            axisValueFontSize: 22,
            xAxisLabelFontSize: 26,
            gridLineWidth: 1,
            gridLineOpacity: 0.4,
            legendMarkerSize: 16,
            legendFontSize: 24,
            legendRowSpacing: 32,
            legendItemSpacing: 10,
            legendTopPadding: 8,
            chartPadding: 60
        ),
        interactiveVerticalSpacing: 12
    )
}
