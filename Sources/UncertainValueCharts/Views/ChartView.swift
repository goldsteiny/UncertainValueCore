//
//  ChartView.swift
//  BoundedValuesCharts
//
//  Interactive chart view with pan/zoom support.
//

import Charts
import SwiftUI

public struct ChartView: View {
    public let config: ChartConfiguration

    @Binding private var viewport: ChartViewport?

    private let onViewportChanged: ((ChartViewport) -> Void)?
    private let onDoubleTap: (() -> Void)?

    @State private var plotSize: CGSize = .zero
    @GestureState private var gestureTranslation: CGSize = .zero
    @GestureState private var gestureMagnification: CGFloat = 1.0

    public init(
        config: ChartConfiguration,
        viewport: Binding<ChartViewport?>,
        onViewportChanged: ((ChartViewport) -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil
    ) {
        self.config = config
        self._viewport = viewport
        self.onViewportChanged = onViewportChanged
        self.onDoubleTap = onDoubleTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: config.style.interactiveVerticalSpacing) {
            if !config.yAxisLabel.isEmpty {
                Text(config.yAxisLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            interactivePlot
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showLegend {
                ChartLegendView(
                    series: config.series,
                    overlays: config.overlays,
                    markerSize: config.style.legendStyle.markerSize,
                    rowSpacing: config.style.legendStyle.rowSpacing,
                    itemSpacing: config.style.legendStyle.itemSpacing
                )
            }
        }
    }

    private var showLegend: Bool {
        config.series.count > 1 || !config.overlays.isEmpty
    }

    private var plotConfig: ChartConfiguration {
        var updated = config
        if let renderedViewport {
            updated.xDomain = renderedViewport.xDomain
            updated.yDomain = renderedViewport.yDomain
        }
        return updated
    }

    private var interactivePlot: some View {
        Chart { chartMarks(config: plotConfig, style: config.style.markStyles.interactive) }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: config.style.gridLineCount.vertical)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel { Text(AxisFormatting.formattedAxisValue(value) ?? "") }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: config.style.gridLineCount.horizontal)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel { Text(AxisFormatting.formattedAxisValue(value) ?? "") }
                }
            }
            .chartXAxisLabel(config.xAxisLabel, position: .bottom, alignment: .center)
            .chartLegend(.hidden)
            .chartPlotStyle { $0.clipped() }
            .applyChartDomains(xDomain: plotConfig.xDomain, yDomain: plotConfig.yDomain)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    if let plotFrameAnchor = proxy.plotFrame {
                        let plotFrame = geo[plotFrameAnchor]

                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .frame(width: plotFrame.width, height: plotFrame.height)
                            .position(x: plotFrame.midX, y: plotFrame.midY)
                            .gesture(panAndZoomGesture)
                            .highPriorityGesture(
                                TapGesture(count: 2).onEnded {
                                    onDoubleTap?()
                                }
                            )
                            .onAppear {
                                plotSize = plotFrame.size
                            }
                            .onChange(of: plotFrame.size) { _, newSize in
                                plotSize = newSize
                            }
                    } else {
                        EmptyView()
                    }
                }
            }
    }

    private var renderedViewport: ChartViewport? {
        guard let base = viewport else { return nil }

        let panned = ChartViewportGestures.panned(
            from: base,
            translation: gestureTranslation,
            plotSize: plotSize
        )

        return ChartViewportGestures.zoomed(
            from: panned,
            magnification: gestureMagnification,
            minimumSpan: config.style.minimumDomainSpan
        )
    }

    private var panAndZoomGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($gestureTranslation) { value, state, _ in
                    state = value.translation
                },
            MagnificationGesture()
                .updating($gestureMagnification) { value, state, _ in
                    state = value
                }
        )
        .onEnded { value in
            guard let start = viewport else { return }

            let translation = value.first?.translation ?? .zero
            let magnification = value.second ?? 1.0

            let panned = ChartViewportGestures.panned(
                from: start,
                translation: translation,
                plotSize: plotSize
            )

            let zoomed = ChartViewportGestures.zoomed(
                from: panned,
                magnification: magnification,
                minimumSpan: config.style.minimumDomainSpan
            )

            viewport = zoomed
            onViewportChanged?(zoomed)
        }
    }
}
