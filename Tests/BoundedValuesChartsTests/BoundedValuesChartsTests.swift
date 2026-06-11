import CoreGraphics
import Foundation
import Testing
@testable import BoundedValuesCharts
import UncertainValueSupport

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

    @Test func fitToDataIncludesErrorBounds() {
        let points = [
            ChartPoint(
                x: ChartValue(value: 10.0, lowerBound: 8.0, upperBound: 12.0),
                y: ChartValue(value: 100.0, lowerBound: 95.0, upperBound: 105.0)
            ),
            ChartPoint(
                x: ChartValue(value: 20.0, lowerBound: 19.0, upperBound: 21.0),
                y: ChartValue(value: 120.0, lowerBound: 110.0, upperBound: 130.0)
            )
        ]
        let series = ChartSeries(label: "Series", color: .blue, points: points)
        let style = ChartStyle.default

        let viewport = ChartViewport.fitToData(series: [series], style: style)
        #expect(viewport != nil)
        guard let viewport else { return }

        let expectedX = expectedDomain(min: 8.0, max: 21.0, style: style)
        let expectedY = expectedDomain(min: 95.0, max: 130.0, style: style)

        #expect(isRangeApproximatelyEqual(viewport.xDomain, expected: expectedX))
        #expect(isRangeApproximatelyEqual(viewport.yDomain, expected: expectedY))
    }

    @Test func fitToDataIncludesFlatYAxisErrorBounds() {
        let areaError = 0.3535533906
        let points = [
            ChartPoint(
                x: ChartValue(value: 1.75, lowerBound: 1.6996108891, upperBound: 1.8003891109),
                y: ChartValue(value: 7.0, lowerBound: 7.0 - 0.2015564437, upperBound: 7.0 + 0.2015564437)
            ),
            ChartPoint(
                x: ChartValue(value: 2.285714286, lowerBound: 2.2144316362, upperBound: 2.3569969358),
                y: ChartValue(value: 7.0, lowerBound: 7.0 - 0.218303115, upperBound: 7.0 + 0.218303115)
            ),
            ChartPoint(
                x: ChartValue(value: 7.0, lowerBound: 6.6464466094, upperBound: 7.3535533906),
                y: ChartValue(value: 7.0, lowerBound: 7.0 - areaError, upperBound: 7.0 + areaError)
            )
        ]
        let series = ChartSeries(label: "Series", color: .red, points: points)
        let style = ChartStyle.default

        let viewport = ChartViewport.fitToData(series: [series], style: style)
        #expect(viewport != nil)
        guard let viewport else { return }

        let expectedY = expectedDomain(min: 7.0 - areaError, max: 7.0 + areaError, style: style)
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

    @Test func overlayBandsDoNotForceLegend() {
        let series = makeSeries(label: "A")
        let band = ChartOverlayBand(
            label: "Fit Range",
            color: .blue,
            xRange: 1...2
        )
        let config = ChartConfiguration(series: [series], overlayBands: [band])

        #expect(config.overlayBands == [band])
        #expect(config.shouldShowLegend == false)
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

struct ChartAxisScaleTests {
    @Test func linearScaleIsIdentity() {
        #expect(ChartAxisScale.linear.position(of: 3.5) == 3.5)
        #expect(ChartAxisScale.linear.value(atPosition: -2.0) == -2.0)
        #expect(ChartAxisScale.linear.isRepresentable(-5.0))
        #expect(!ChartAxisScale.linear.isRepresentable(.infinity))
    }

    @Test func log10ScaleMapsDecadesAndRoundTrips() {
        let scale = ChartAxisScale.log10

        #expect(isApproximatelyEqual(scale.position(of: 100.0) ?? .nan, 2.0))
        #expect(isApproximatelyEqual(scale.value(atPosition: 3.0), 1000.0, accuracy: 1e-9))

        let value = 7.3
        let roundTripped = scale.value(atPosition: scale.position(of: value) ?? .nan)
        #expect(isApproximatelyEqual(roundTripped, value, accuracy: 1e-9))
    }

    @Test func log10ScaleRejectsNonPositiveValues() {
        #expect(!ChartAxisScale.log10.isRepresentable(0.0))
        #expect(!ChartAxisScale.log10.isRepresentable(-1.0))
        #expect(ChartAxisScale.log10.position(of: 0.0) == nil)
        #expect(ChartAxisScale.log10.positionRange(of: -1.0...10.0) == nil)
    }

    @Test func renderableDomainTruncatesNonPositiveLowerBound() {
        let truncated = ChartAxisScale.log10.renderableDomain(of: -5.0...100.0)
        #expect(truncated != nil)
        if let truncated {
            #expect(truncated.lowerBound > 0)
            #expect(isApproximatelyEqual(truncated.upperBound, 100.0))
        }

        #expect(ChartAxisScale.log10.renderableDomain(of: -5.0...0.0) == nil)
        #expect(ChartAxisScale.linear.renderableDomain(of: -5.0...0.0) == -5.0...0.0)
    }
}

struct ChartViewportLogScaleTests {
    @Test func fitToDataOnLogAxisExcludesNonPositiveValuesAndPadsInDecades() {
        let points = [
            ChartPoint(x: ChartValue(1.0), y: ChartValue(1.0)),
            ChartPoint(x: ChartValue(100.0), y: ChartValue(10.0)),
            ChartPoint(x: ChartValue(-4.0), y: ChartValue(5.0))
        ]
        let series = ChartSeries(label: "Series", color: .blue, points: points)
        let style = ChartStyle.default

        let viewport = ChartViewport.fitToData(series: [series], style: style, xScale: .log10)
        #expect(viewport != nil)
        guard let viewport else { return }

        // x positions span 0...2 decades; padding fraction 0.05 widens to -0.1...2.1.
        let expectedX = pow(10.0, -0.1)...pow(10.0, 2.1)
        #expect(isRangeApproximatelyEqual(viewport.xDomain, expected: expectedX, accuracy: 1e-6))

        // The excluded point's y value no longer constrains the y fit.
        let expectedY = expectedDomain(min: 1.0, max: 10.0, style: style)
        #expect(isRangeApproximatelyEqual(viewport.yDomain, expected: expectedY, accuracy: 1e-6))
    }

    @Test func fitToDataIgnoresNonPositiveErrorBoundsOnLogAxis() {
        let points = [
            ChartPoint(
                x: ChartValue(value: 10.0, lowerBound: -1.0, upperBound: 20.0),
                y: ChartValue(1.0)
            )
        ]
        let series = ChartSeries(label: "Series", color: .blue, points: points)

        let viewport = ChartViewport.fitToData(series: [series], xScale: .log10)
        #expect(viewport != nil)
        guard let viewport else { return }

        #expect(viewport.xDomain.lowerBound > 0)
    }

    @Test func panOnLogAxisShiftsDecades() {
        let start = ChartViewport(xDomain: 1.0...100.0, yDomain: 0.0...10.0)

        let panned = start.panned(
            translation: CGSize(width: -50.0, height: 0.0),
            plotSize: CGSize(width: 100.0, height: 100.0),
            xScale: .log10
        )

        #expect(isRangeApproximatelyEqual(panned.xDomain, expected: 10.0...1000.0, accuracy: 1e-6))
        #expect(isRangeApproximatelyEqual(panned.yDomain, expected: 0.0...10.0))
    }

    @Test func zoomOnLogAxisKeepsGeometricCenter() {
        let start = ChartViewport(xDomain: 1.0...10000.0, yDomain: 0.0...10.0)

        let zoomed = start.zoomed(magnification: 2.0, minimumSpan: 0.001, xScale: .log10)

        // Positions 0...4 zoomed ×2 around center 2 give 1...3 → 10...1000.
        #expect(isRangeApproximatelyEqual(zoomed.xDomain, expected: 10.0...1000.0, accuracy: 1e-6))
    }
}

struct ChartScaleSanitizingTests {
    @Test func sanitizerDropsNonRepresentablePointsAndClampsErrorBounds() {
        let points = [
            ChartPoint(
                x: ChartValue(5.0),
                y: ChartValue(value: 10.0, lowerBound: -2.0, upperBound: 20.0)
            ),
            ChartPoint(x: ChartValue(6.0), y: ChartValue(-3.0))
        ]
        let series = ChartSeries(label: "Series", color: .blue, points: points)
        let config = ChartConfiguration(
            series: [series],
            xAxis: ChartAxisConfiguration(domain: 0.0...10.0),
            yAxis: ChartAxisConfiguration(domain: 0.5...100.0, scale: .log10)
        )

        let sanitized = config.sanitizedForScales()

        #expect(sanitized.series.first?.points.count == 1)
        let yValue = sanitized.series.first?.points.first?.y
        #expect(yValue?.value == 10.0)
        #expect(yValue?.lowerBound == 0.5)
        #expect(yValue?.upperBound == 20.0)
    }

    @Test func sanitizerSplitsOverlaySegmentsAtNonRepresentableVertices() {
        let segment = ChartOverlaySegment(points: [
            CGPoint(x: 1.0, y: 1.0),
            CGPoint(x: 2.0, y: 2.0),
            CGPoint(x: 3.0, y: -1.0),
            CGPoint(x: 4.0, y: 4.0),
            CGPoint(x: 5.0, y: 5.0)
        ])
        let line = ChartOverlayLine(label: "Line", color: .red, segments: [segment])
        let config = ChartConfiguration(
            series: [],
            overlays: [line],
            yAxis: ChartAxisConfiguration(scale: .log10)
        )

        let sanitized = config.sanitizedForScales()

        #expect(sanitized.overlays.first?.segments.count == 2)
        #expect(sanitized.overlays.first?.segments.first?.points.count == 2)
    }

    @Test func sanitizerClampsBandsToLogXAxisDomainFloor() {
        let band = ChartOverlayBand(label: "Band", color: .blue, xRange: -5.0...50.0)
        let config = ChartConfiguration(
            series: [],
            overlayBands: [band],
            xAxis: ChartAxisConfiguration(domain: 1.0...100.0, scale: .log10)
        )

        let sanitized = config.sanitizedForScales()

        #expect(sanitized.overlayBands.first?.xRange == 1.0...50.0)
    }

    @Test func linearConfigurationPassesThroughUnchanged() {
        let series = makeSeries(
            label: "Series",
            points: [ChartPoint(x: ChartValue(-5.0), y: ChartValue(-7.0))]
        )
        let config = ChartConfiguration(series: [series])

        let sanitized = config.sanitizedForScales()

        #expect(sanitized == config)
    }
}
