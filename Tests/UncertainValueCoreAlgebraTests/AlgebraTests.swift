import Testing
@testable import UncertainValueCoreAlgebra

private struct DoublePair: Equatable, Sendable {
    let first: Double
    let second: Double

    init(_ first: Double, _ second: Double) {
        self.first = first
        self.second = second
    }
}

extension DoublePair: Zero {
    static var zero: DoublePair { DoublePair(0, 0) }
}

extension DoublePair: AdditiveSemigroup {
    static func + (lhs: DoublePair, rhs: DoublePair) -> DoublePair {
        DoublePair(lhs.first + rhs.first, lhs.second + rhs.second)
    }
}

extension DoublePair: AdditiveGroup {
    static prefix func - (operand: DoublePair) -> DoublePair {
        DoublePair(-operand.first, -operand.second)
    }
}

extension DoublePair: LeftModule {
    typealias Scalar = Double

    func leftScaled(by scalar: Double) -> DoublePair {
        DoublePair(first * scalar, second * scalar)
    }
}

private struct WrappedDouble: Equatable, Sendable {
    let raw: Double

    init(_ raw: Double) {
        self.raw = raw
    }
}

extension WrappedDouble: Zero {
    static var zero: WrappedDouble { WrappedDouble(0) }
}

extension WrappedDouble: One {
    static var one: WrappedDouble { WrappedDouble(1) }
}

extension WrappedDouble: AdditiveSemigroup {
    static func + (lhs: WrappedDouble, rhs: WrappedDouble) -> WrappedDouble {
        WrappedDouble(lhs.raw + rhs.raw)
    }
}

extension WrappedDouble: AdditiveGroup {
    static prefix func - (operand: WrappedDouble) -> WrappedDouble {
        WrappedDouble(-operand.raw)
    }
}

extension WrappedDouble: MultiplicativeSemigroup {
    static func * (lhs: WrappedDouble, rhs: WrappedDouble) -> WrappedDouble {
        WrappedDouble(lhs.raw * rhs.raw)
    }
}

extension WrappedDouble: MultiplicativeMonoidWithUnits {
    var unit: Unit<WrappedDouble>? {
        guard !isZero else { return nil }
        return Unit(unchecked: self, reciprocal: WrappedDouble(1 / raw))
    }
}

extension WrappedDouble: Signed {
    var signum: Signum {
        if raw == 0 { return .zero }
        return raw < 0 ? .negative : .positive
    }

    var flippedSign: WrappedDouble {
        WrappedDouble(-raw)
    }
}

extension WrappedDouble: AbsoluteValueDecomposable {
    var absolute: WrappedDouble {
        WrappedDouble(Swift.abs(raw))
    }
}

private struct SumPrimitive: Equatable, Sendable {
    let raw: Int

    init(_ raw: Int) {
        self.raw = raw
    }
}

extension SumPrimitive: Zero {
    static var zero: SumPrimitive { SumPrimitive(0) }
}

extension SumPrimitive: AdditivelySummable {
    static func sum(_ values: NonEmpty<SumPrimitive>) -> SumPrimitive {
        SumPrimitive(values.tail.reduce(values.head.raw) { $0 + $1.raw })
    }
}

extension SumPrimitive: AdditiveMonoid {}

private struct ProductPrimitive: Equatable, Sendable {
    let raw: Int

    init(_ raw: Int) {
        self.raw = raw
    }
}

extension ProductPrimitive: One {
    static var one: ProductPrimitive { ProductPrimitive(1) }
}

extension ProductPrimitive: MultiplicativelyProductable {
    static func product(_ values: NonEmpty<ProductPrimitive>) -> ProductPrimitive {
        ProductPrimitive(values.tail.reduce(values.head.raw) { $0 * $1.raw })
    }
}

extension ProductPrimitive: MultiplicativeMonoid {}

private func requireFloatingPointFieldAlgebra<T: FloatingPointFieldAlgebra>(_ value: T) -> T {
    value
}

struct UtilityTypeTests {
    @Test func nonEmptyConstructMapReduce() {
        let values = NonEmpty(1, [2, 3])
        #expect(values.array == [1, 2, 3])
        #expect(values.count == 3)
        #expect(values.map { $0 * 2 }.array == [2, 4, 6])
        #expect(values.reduce(+, initialTransform: { $0 }) == 6)
    }

    @Test func nonZeroForWrappedDoubleAndInt() {
        #expect(NonZero<WrappedDouble>(.zero) == nil)
        #expect(NonZero<WrappedDouble>(WrappedDouble(2)) != nil)
        #expect(NonZero<Int>(0) == nil)
        #expect(NonZero<Int>(5)?.value == 5)

        let wrappedTwo = NonZero<WrappedDouble>(WrappedDouble(2))
        #expect(wrappedTwo?.unit?.reciprocal == WrappedDouble(0.5))
    }

    @Test func unitWitnessFromPartialReciprocal() {
        #expect(Unit(WrappedDouble.zero) == nil)

        let unit = Unit(WrappedDouble(4))
        #expect(unit?.value == WrappedDouble(4))
        #expect(unit?.reciprocal == WrappedDouble(0.25))
    }
}

struct AdditiveDerivationTests {
    @Test func sumDerivedFromBinaryPlus() {
        let values = NonEmpty(DoublePair(1, 2), [DoublePair(3, 4), DoublePair(5, 6)])
        #expect(DoublePair.sum(values) == DoublePair(9, 12))
    }

    @Test func binaryPlusDerivedFromSumPrimitive() {
        #expect(SumPrimitive(2) + SumPrimitive(3) == SumPrimitive(5))
    }

    @Test func arraySumForMonoid() {
        #expect([DoublePair(1, 1), DoublePair(2, 3)].sum() == DoublePair(3, 4))
        #expect(([DoublePair]() as [DoublePair]).sum() == .zero)
    }

    @Test func semigroupArraySumResult() {
        #expect([DoublePair(1, 2), DoublePair(3, 4)].sumResult() == .success(DoublePair(4, 6)))
        #expect(([] as [DoublePair]).sumResult() == .failure(.init()))
    }

    @Test func directSumAlias() {
        #expect(DoublePair.directSum(DoublePair(2, 3), DoublePair(4, 5)) == DoublePair(6, 8))
    }
}

struct MultiplicativeDerivationTests {
    @Test func productDerivedFromBinaryStar() {
        let values = NonEmpty(WrappedDouble(2), [WrappedDouble(3), WrappedDouble(4)])
        #expect(WrappedDouble.product(values) == WrappedDouble(24))
    }

    @Test func binaryStarDerivedFromProductPrimitive() {
        #expect(ProductPrimitive(3) * ProductPrimitive(4) == ProductPrimitive(12))
    }

    @Test func arrayProductForMonoid() {
        #expect([WrappedDouble(2), WrappedDouble(5)].product() == WrappedDouble(10))
        #expect(([WrappedDouble]() as [WrappedDouble]).product() == .one)
    }

    @Test func semigroupArrayProductResult() {
        #expect([WrappedDouble(2), WrappedDouble(5)].productResult() == .success(WrappedDouble(10)))
        #expect(([] as [WrappedDouble]).productResult() == .failure(.init()))
    }
}

struct ReciprocalAndDivisionTests {
    @Test func reciprocalSuccessAndFailure() throws {
        let reciprocal = try WrappedDouble(4).reciprocal().get()
        #expect(reciprocal == WrappedDouble(0.25))

        switch WrappedDouble.zero.reciprocal() {
        case .success:
            Issue.record("Expected reciprocal failure for zero")
        case .failure(let error):
            #expect(error.context == nil)
        }
    }

    @Test func divisionVariants() throws {
        let result = try WrappedDouble(9).divided(by: WrappedDouble(3)).get()
        #expect(result == WrappedDouble(3))

        let threeUnit = try #require(Unit(WrappedDouble(3)))
        #expect(WrappedDouble(9).divided(by: threeUnit) == WrappedDouble(3))
        #expect(WrappedDouble(9) / threeUnit == WrappedDouble(3))

        switch WrappedDouble(9).divided(by: .zero) {
        case .success:
            Issue.record("Expected division failure for non-unit denominator (zero here)")
        case .failure(let error):
            #expect(error.context == nil)
        }
    }
}

struct LinearCombinationTests {
    @Test func linearCombinationAndWeightedSum() {
        let terms = NonEmpty((2.0, DoublePair(1, 2)), [(-1.0, DoublePair(3, 4))])
        #expect(DoublePair.linearCombination(terms) == DoublePair(-1, 0))

        let weightedTerms = NonEmpty(
            (weight: 2.0, value: DoublePair(1, 2)),
            [(weight: -1.0, value: DoublePair(3, 4))]
        )
        #expect(DoublePair.weightedSum(weightedTerms) == DoublePair(-1, 0))

        #expect(
            DoublePair.linearCombination(2.0, DoublePair(1, 2), -1.0, DoublePair(3, 4)) == DoublePair(-1, 0)
        )
    }

    @Test func arrayEntryPointsAndScaleDown() throws {
        let emptyTerms: [(Double, DoublePair)] = []
        #expect(DoublePair.linearCombination(emptyTerms) == nil)

        let nonEmpty = try #require(
            DoublePair.linearCombination([(2.0, DoublePair(1, 2)), (3.0, DoublePair(4, 5))])
        )
        #expect(nonEmpty == DoublePair(14, 19))

        let downscaled = try DoublePair(8, 10).scaledDown(by: 2.0).get()
        #expect(downscaled == DoublePair(4, 5))

        switch DoublePair(8, 10).scaledDown(by: 0.0) {
        case .success:
            Issue.record("Expected scale-down failure for non-unit scalar (zero here)")
        case .failure:
            break
        }

        let twoUnit = try #require(Unit(2.0))
        #expect(DoublePair(8, 10).scaledDown(by: twoUnit) == DoublePair(4, 5))
    }
}

struct SignAndAbsoluteTests {
    @Test func signAndConvenienceFlags() {
        #expect(WrappedDouble(-2).signum == .negative)
        #expect(WrappedDouble(0).signum == .zero)
        #expect(WrappedDouble(2).signum == .positive)

        #expect(WrappedDouble(3).isPositive)
        #expect(WrappedDouble(-3).isNegative)
        #expect(WrappedDouble(0).isSignZero)
        #expect(-WrappedDouble(7) == WrappedDouble(-7))
    }

    @Test func absoluteAndArrayHelpers() {
        let values = [WrappedDouble(-1), WrappedDouble(2), WrappedDouble(-3)]
        #expect(values.absolutes == [WrappedDouble(1), WrappedDouble(2), WrappedDouble(3)])
        #expect([Signum.negative, .negative, .positive].product() == .positive)
        #expect([Signum.negative, .zero, .positive].product() == .zero)
    }
}

struct ErrorBridgeAndStdlibBridgeTests {
    @Test func typedErrorToUmbrellaErrorMapping() {
        let reciprocalFailure: Result<WrappedDouble, ReciprocalUnavailableError> = .failure(.init("x"))
        let mapped = reciprocalFailure.mapToAlgebraError()
        #expect(mapped == .failure(.reciprocalUnavailable(.init("x"))))
    }

    @Test func floatingPointBridgeFixtureCompilesAndBehaves() throws {
        let doubleValue = requireFloatingPointFieldAlgebra(4.0)
        let reciprocal = try doubleValue.reciprocal().get()
        #expect(Swift.abs(reciprocal - 0.25) < 1e-12)
    }
}
