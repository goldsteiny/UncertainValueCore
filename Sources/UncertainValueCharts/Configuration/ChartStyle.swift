//
//  ChartStyle.swift
//  BoundedValuesCharts
//
//  Style constants for chart rendering.
//

import CoreGraphics
import Foundation

public struct ChartStyle: Sendable, Equatable {
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
        public var axisLabelFontSize: CGFloat
        public var axisValueFontSize: CGFloat
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
            axisLabelFontSize: CGFloat,
            axisValueFontSize: CGFloat,
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
            self.axisLabelFontSize = axisLabelFontSize
            self.axisValueFontSize = axisValueFontSize
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

    public var domainPaddingFraction: Double
    public var minimumDomainSpan: Double
    public var markStyles: MarkStyles
    public var legendStyle: LegendStyle
    public var exportStyle: ExportStyle
    public var interactiveVerticalSpacing: CGFloat

    public init(
        domainPaddingFraction: Double,
        minimumDomainSpan: Double,
        markStyles: MarkStyles,
        legendStyle: LegendStyle,
        exportStyle: ExportStyle,
        interactiveVerticalSpacing: CGFloat
    ) {
        self.domainPaddingFraction = domainPaddingFraction
        self.minimumDomainSpan = minimumDomainSpan
        self.markStyles = markStyles
        self.legendStyle = legendStyle
        self.exportStyle = exportStyle
        self.interactiveVerticalSpacing = interactiveVerticalSpacing
    }

    public static let `default` = ChartStyle(
        domainPaddingFraction: ChartConstants.StyleDefaults.domainPaddingFraction,
        minimumDomainSpan: ChartConstants.StyleDefaults.minimumDomainSpan,
        markStyles: MarkStyles(
            interactive: MarkStyle(
                pointSymbolSize: ChartConstants.StyleDefaults.Mark.interactivePointSymbolSize,
                errorLineWidth: ChartConstants.StyleDefaults.Mark.interactiveErrorLineWidth,
                errorOpacity: ChartConstants.StyleDefaults.Mark.interactiveErrorOpacity,
                overlayLineWidth: ChartConstants.StyleDefaults.Mark.interactiveOverlayLineWidth
            ),
            export: MarkStyle(
                pointSymbolSize: ChartConstants.StyleDefaults.Mark.exportPointSymbolSize,
                errorLineWidth: ChartConstants.StyleDefaults.Mark.exportErrorLineWidth,
                errorOpacity: ChartConstants.StyleDefaults.Mark.exportErrorOpacity,
                overlayLineWidth: ChartConstants.StyleDefaults.Mark.exportOverlayLineWidth
            )
        ),
        legendStyle: LegendStyle(
            markerSize: ChartConstants.StyleDefaults.Legend.markerSize,
            rowSpacing: ChartConstants.StyleDefaults.Legend.rowSpacing,
            itemSpacing: ChartConstants.StyleDefaults.Legend.itemSpacing
        ),
        exportStyle: ExportStyle(
            verticalSpacing: ChartConstants.StyleDefaults.Export.verticalSpacing,
            axisLabelFontSize: ChartConstants.StyleDefaults.Export.axisLabelFontSize,
            axisValueFontSize: ChartConstants.StyleDefaults.Export.axisValueFontSize,
            gridLineWidth: ChartConstants.StyleDefaults.Export.gridLineWidth,
            gridLineOpacity: ChartConstants.StyleDefaults.Export.gridLineOpacity,
            legendMarkerSize: ChartConstants.StyleDefaults.Export.legendMarkerSize,
            legendFontSize: ChartConstants.StyleDefaults.Export.legendFontSize,
            legendRowSpacing: ChartConstants.StyleDefaults.Export.legendRowSpacing,
            legendItemSpacing: ChartConstants.StyleDefaults.Export.legendItemSpacing,
            legendTopPadding: ChartConstants.StyleDefaults.Export.legendTopPadding,
            chartPadding: ChartConstants.StyleDefaults.Export.chartPadding
        ),
        interactiveVerticalSpacing: ChartConstants.StyleDefaults.interactiveVerticalSpacing
    )
}
