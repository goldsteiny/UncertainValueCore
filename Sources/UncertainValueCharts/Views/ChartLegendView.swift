//
//  ChartLegendView.swift
//  BoundedValuesCharts
//
//  Legend component shared by interactive and export views.
//

import SwiftUI

public struct ChartLegendView: View {
    private let items: [LegendItem]

    private let markerSize: CGFloat
    private let font: Font
    private let foregroundColor: Color
    private let rowSpacing: CGFloat
    private let itemSpacing: CGFloat

    public init(
        series: [ChartSeries],
        overlays: [ChartOverlayLine],
        markerSize: CGFloat = ChartStyle.default.legendStyle.markerSize,
        font: Font = .caption,
        foregroundColor: Color = .secondary,
        rowSpacing: CGFloat = ChartStyle.default.legendStyle.rowSpacing,
        itemSpacing: CGFloat = ChartStyle.default.legendStyle.itemSpacing
    ) {
        let seriesItems = series.map { item in
            LegendItem(id: item.id, label: item.label, color: item.color.swiftUIColor, markerStyle: .circle)
        }
        let overlayItems = overlays.map { item in
            LegendItem(id: item.id, label: item.label, color: item.color.swiftUIColor, markerStyle: .line)
        }
        self.items = seriesItems + overlayItems
        self.markerSize = markerSize
        self.font = font
        self.foregroundColor = foregroundColor
        self.rowSpacing = rowSpacing
        self.itemSpacing = itemSpacing
    }

    public var body: some View {
        HStack(spacing: rowSpacing) {
            ForEach(items) { item in
                HStack(spacing: itemSpacing) {
                    marker(for: item)
                    Text(item.label)
                        .font(font)
                        .foregroundColor(foregroundColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func marker(for item: LegendItem) -> some View {
        switch item.markerStyle {
        case .circle:
            Circle()
                .fill(item.color)
                .frame(width: markerSize, height: markerSize)
        case .line:
            Capsule()
                .fill(item.color)
                .frame(
                    width: markerSize * ChartConstants.LegendLayout.lineWidthMultiplier,
                    height: max(
                        ChartConstants.LegendLayout.minimumLineHeight,
                        markerSize / ChartConstants.LegendLayout.lineHeightDivisor
                    )
                )
        }
    }
}

private struct LegendItem: Identifiable, Equatable {
    enum MarkerStyle: Equatable {
        case circle
        case line
    }

    let id: UUID
    let label: String
    let color: Color
    let markerStyle: MarkerStyle
}
