import CoreGraphics
import Foundation
import Testing
@testable import BoundedValuesCharts
import UncertainValueCoreAlgebra

#if canImport(UIKit)
import UIKit
#endif

private let chartDefaultsLock = NSLock()

private struct TestBoundedValue: BoundedValuesProviding {
    let value: Double
    let lowerBound: Double
    let upperBound: Double
}

private enum TestConstants {
    static let accuracy: Double = 1e-12
}

private enum ChartDefaultsTestValues {
    static let customGridLineCount: Int = 7
    static let customLegendThreshold: Int = 3
    static let axisFormatterFractionDigits: Int = 1
    static let axisFormatInput: Double = 1.234
    static let axisFormatExpected: String = "1.2"
    static let customMinimumSpan: Double = 0.123
    static let rendererSize: CGSize = CGSize(width: 320, height: 240)
    static let nonFiniteValue: Double = .infinity
    static let nanValue: Double = .nan
}

struct ChartValueTests {
    @Test func initFromBoundedValueClampsInfiniteBounds() {
        let bounded = TestBoundedValue(value: 2.0, lowerBound: -.infinity, upperBound: .infinity)

        let chartValue = ChartValue(from: bounded)

        #expect(isApproximatelyEqual(chartValue.value, 2.0))
        #expect(isApproximatelyEqual(chartValue.lowerBound, 2.0))
        #expect(isApproximatelyEqual(chartValue.upperBound, 2.0))
    }

    @Test func initFromBoundedValuePreservesFiniteUpperBound() {
        let bounded = TestBoundedValue(value: 3.0, lowerBound: -.infinity, upperBound: 4.0)

        let chartValue = ChartValue(from: bounded)

        #expect(isApproximatelyEqual(chartValue.lowerBound, 3.0))
        #expect(isApproximatelyEqual(chartValue.upperBound, 4.0))
    }
}

struct ChartViewportFitTests {
    @Test func fitToDataAddsPaddingAroundPoints() {
        let points = [
            ChartPoint(x: ChartValue(0.0), y: ChartValue(0.0)),
            ChartPoint(x: ChartValue(10.0), y: ChartValue(20.0))
        ]
        let series = ChartSeries(label: "Series", color: .blue, points: points)
        let style = ChartStyle.default

        let viewport = ChartViewport.fitToData(series: [series], style: style)
        #expect(viewport != nil)
        guard let viewport else { return }

        let expectedX = expectedDomain(min: 0.0, max: 10.0, style: style)
        let expectedY = expectedDomain(min: 0.0, max: 20.0, style: style)

        #expect(isRangeApproximatelyEqual(viewport.xDomain, expected: expectedX))
        #expect(isRangeApproximatelyEqual(viewport.yDomain, expected: expectedY))
    }

    @Test func fitToDataUsesMinimumSpanForSinglePoint() {
        let points = [ChartPoint(x: ChartValue(5.0), y: ChartValue(7.0))]
        let series = ChartSeries(label: "Series", color: .red, points: points)
        let style = ChartStyle.default

        let viewport = ChartViewport.fitToData(series: [series], style: style)
        #expect(viewport != nil)
        guard let viewport else { return }

        #expect(viewport.xSpan >= style.minimumDomainSpan)
        #expect(viewport.ySpan >= style.minimumDomainSpan)
    }
}

struct ChartViewportInteractionTests {
    @Test func panTranslatesDomains() {
        let start = ChartViewport(xDomain: 0.0...10.0, yDomain: 0.0...10.0)
        let translation = CGSize(width: 10.0, height: 20.0)
        let plotSize = CGSize(width: 100.0, height: 100.0)

        let panned = start.panned(translation: translation, plotSize: plotSize)

        #expect(isRangeApproximatelyEqual(panned.xDomain, expected: -1.0...9.0))
        #expect(isRangeApproximatelyEqual(panned.yDomain, expected: 2.0...12.0))
    }

    @Test func panWithZeroPlotSizeReturnsStart() {
        let start = ChartViewport(xDomain: 0.0...10.0, yDomain: 0.0...10.0)
        let translation = CGSize(width: 10.0, height: 20.0)
        let plotSize = CGSize(width: 0.0, height: 100.0)

        let panned = start.panned(translation: translation, plotSize: plotSize)

        #expect(panned == start)
    }

    @Test func panWithZeroSpanReturnsStart() {
        let start = ChartViewport(xDomain: 5.0...5.0, yDomain: 2.0...2.0)
        let translation = CGSize(width: 10.0, height: 20.0)
        let plotSize = CGSize(width: 100.0, height: 100.0)

        let panned = start.panned(translation: translation, plotSize: plotSize)

        #expect(panned == start)
    }

    @Test func zoomAdjustsSpanAroundCenter() {
        let start = ChartViewport(xDomain: 0.0...10.0, yDomain: 0.0...10.0)

        let zoomed = start.zoomed(magnification: 2.0, minimumSpan: 0.1)

        #expect(isRangeApproximatelyEqual(zoomed.xDomain, expected: 2.5...7.5))
        #expect(isRangeApproximatelyEqual(zoomed.yDomain, expected: 2.5...7.5))
    }

    @Test func zoomRespectsMinimumSpan() {
        let start = ChartViewport(xDomain: 0.0...10.0, yDomain: 0.0...10.0)

        let zoomed = start.zoomed(magnification: 20.0, minimumSpan: 4.0)

        #expect(isRangeApproximatelyEqual(zoomed.xDomain, expected: 3.0...7.0))
        #expect(isRangeApproximatelyEqual(zoomed.yDomain, expected: 3.0...7.0))
    }

    @Test func zoomIgnoresInvalidMagnification() {
        let start = ChartViewport(xDomain: 0.0...10.0, yDomain: 0.0...10.0)

        let zoomedZero = start.zoomed(magnification: 0.0, minimumSpan: 0.1)
        let zoomedNegative = start.zoomed(magnification: -2.0, minimumSpan: 0.1)
        let zoomedInfinite = start.zoomed(magnification: .infinity, minimumSpan: 0.1)

        #expect(zoomedZero == start)
        #expect(zoomedNegative == start)
        #expect(zoomedInfinite == start)
    }
}

struct ChartViewportEdgeTests {
    @Test func fitToDataReturnsNilForEmptySeries() {
        let viewport = ChartViewport.fitToData(series: [])
        #expect(viewport == nil)
    }

    @Test func fitToDataReturnsNilForNaNValues() {
        let points = [ChartPoint(x: ChartValue(ChartDefaultsTestValues.nanValue), y: ChartValue(1.0))]
        let series = ChartSeries(label: "Series", color: .green, points: points)

        let viewport = ChartViewport.fitToData(series: [series])
        #expect(viewport == nil)
    }

    @Test func fitToDataReturnsNilForInfiniteValues() {
        let points = [ChartPoint(x: ChartValue(0.0), y: ChartValue(ChartDefaultsTestValues.nonFiniteValue))]
        let series = ChartSeries(label: "Series", color: .orange, points: points)

        let viewport = ChartViewport.fitToData(series: [series])
        #expect(viewport == nil)
    }
}

struct ChartDefaultsTests {
    @Test func styleOverrideAppliesToConfiguration() throws {
        var customStyle = ChartStyle.default
        customStyle.minimumDomainSpan = ChartDefaultsTestValues.customMinimumSpan

        try withChartDefaults(style: customStyle) {
            let config = ChartConfiguration(series: [makeSeries(label: "Series")])
            #expect(config.style == customStyle)
        }
    }

    @Test func axisGridLineCountOverrideAppliesToAxisConfiguration() throws {
        try withChartDefaults(gridLineCount: ChartDefaultsTestValues.customGridLineCount) {
            let axis = ChartAxisConfiguration()
            #expect(axis.gridLineCount == ChartDefaultsTestValues.customGridLineCount)
        }
    }

    @Test func axisFormattingUsesCustomNumberFormatter() throws {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = ChartDefaultsTestValues.axisFormatterFractionDigits
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false

        try withChartDefaults(numberFormatter: formatter) {
            let formatted = AxisFormatting.formattedAxisValue(ChartDefaultsTestValues.axisFormatInput)
            #expect(formatted == ChartDefaultsTestValues.axisFormatExpected)
        }
    }

    @Test func legendVisibilityRespectsDefaultThreshold() throws {
        try withChartDefaults {
            let seriesA = makeSeries(label: "A")
            let seriesB = makeSeries(label: "B")

            let singleSeries = ChartConfiguration(series: [seriesA])
            #expect(singleSeries.shouldShowLegend == false)

            let twoSeries = ChartConfiguration(series: [seriesA, seriesB])
            #expect(twoSeries.shouldShowLegend)

            let overlay = ChartOverlayLine(label: "Line", color: .orange, segments: [])
            let overlayConfig = ChartConfiguration(series: [seriesA], overlays: [overlay])
            #expect(overlayConfig.shouldShowLegend)
        }
    }

    @Test func legendVisibilityRespectsCustomThreshold() throws {
        let seriesA = makeSeries(label: "A")
        let seriesB = makeSeries(label: "B")
        let seriesC = makeSeries(label: "C")

        try withChartDefaults(minimumSeriesCountForLegend: ChartDefaultsTestValues.customLegendThreshold) {
            let twoSeries = ChartConfiguration(series: [seriesA, seriesB])
            #expect(twoSeries.shouldShowLegend == false)

            let threeSeries = ChartConfiguration(series: [seriesA, seriesB, seriesC])
            #expect(threeSeries.shouldShowLegend)
        }
    }
}

#if canImport(UIKit)
struct ChartImageRendererTests {
    @MainActor
    @Test func renderProducesImage() {
        let series = makeSeries(label: "Series")
        let config = ChartConfiguration(series: [series])

        let image = ChartImageRenderer.render(config, size: ChartDefaultsTestValues.rendererSize)
        #expect(image != nil)
    }
}
#endif

private func withChartDefaults<T>(
    style: ChartStyle? = nil,
    gridLineCount: Int? = nil,
    numberFormatter: NumberFormatter? = nil,
    minimumSeriesCountForLegend: Int? = nil,
    _ body: () throws -> T
) rethrows -> T {
    chartDefaultsLock.lock()
    let previousStyle = ChartDefaults.style
    let previousGridLineCount = ChartDefaults.Axis.gridLineCount
    let previousNumberFormatter = ChartDefaults.AxisFormatting.numberFormatter
    let previousMinimumSeriesCountForLegend = ChartDefaults.LegendLayout.minimumSeriesCountForLegend

    if let style {
        ChartDefaults.style = style
    }
    if let gridLineCount {
        ChartDefaults.Axis.gridLineCount = gridLineCount
    }
    if let numberFormatter {
        ChartDefaults.AxisFormatting.numberFormatter = numberFormatter
    }
    if let minimumSeriesCountForLegend {
        ChartDefaults.LegendLayout.minimumSeriesCountForLegend = minimumSeriesCountForLegend
    }

    defer {
        ChartDefaults.style = previousStyle
        ChartDefaults.Axis.gridLineCount = previousGridLineCount
        ChartDefaults.AxisFormatting.numberFormatter = previousNumberFormatter
        ChartDefaults.LegendLayout.minimumSeriesCountForLegend = previousMinimumSeriesCountForLegend
        chartDefaultsLock.unlock()
    }

    return try body()
}

private func makeSeries(
    label: String,
    color: ChartColor = .blue,
    points: [ChartPoint] = [ChartPoint(x: ChartValue(0.0), y: ChartValue(0.0))]
) -> ChartSeries {
    ChartSeries(label: label, color: color, points: points)
}

private func expectedDomain(min: Double, max: Double, style: ChartStyle) -> ClosedRange<Double> {
    let span = max - min
    let baseSpan = Swift.max(span, style.minimumDomainSpan)
    let halfSpan = baseSpan * (0.5 + style.domainPaddingFraction)
    let center = 0.5 * (min + max)
    return (center - halfSpan)...(center + halfSpan)
}

private func isApproximatelyEqual(
    _ actual: Double,
    _ expected: Double,
    accuracy: Double = TestConstants.accuracy
) -> Bool {
    abs(actual - expected) <= accuracy
}

private func isRangeApproximatelyEqual(
    _ actual: ClosedRange<Double>,
    expected: ClosedRange<Double>,
    accuracy: Double = TestConstants.accuracy
) -> Bool {
    isApproximatelyEqual(actual.lowerBound, expected.lowerBound, accuracy: accuracy)
        && isApproximatelyEqual(actual.upperBound, expected.upperBound, accuracy: accuracy)
}
