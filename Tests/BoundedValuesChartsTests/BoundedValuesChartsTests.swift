import CoreGraphics
import Testing
@testable import BoundedValuesCharts
import UncertainValueCoreAlgebra

private struct TestBoundedValue: BoundedValuesProviding {
    let value: Double
    let lowerBound: Double
    let upperBound: Double
}

private enum TestConstants {
    static let accuracy: Double = 1e-12
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
