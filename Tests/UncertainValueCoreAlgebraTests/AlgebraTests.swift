//
//  AlgebraTests.swift
//  UncertainValueCoreAlgebraTests
//
//  Comprehensive tests for the algebra module's protocols, types, and extensions.
//

import XCTest
@testable import UncertainValueCoreAlgebra

// MARK: - Test Stubs

/// Double-backed scalar conforming to full algebra hierarchy.
struct TestScalar: Equatable, Hashable, Sendable {
    let value: Double

    init(_ value: Double) { self.value = value }
}

extension TestScalar: ZeroContaining {
    static var zero: TestScalar { TestScalar(0) }
    var isZero: Bool { value == 0 }
}

extension TestScalar: OneContaining {
    static var one: TestScalar { TestScalar(1) }
    var isOne: Bool { value == 1 }
}

extension TestScalar: Signed {
    var signum: Signum {
        if value > 0 { return .positive }
        if value < 0 { return .negative }
        return .zero
    }
    var flippedSign: TestScalar { TestScalar(-value) }
}

extension TestScalar: AbsoluteValueDecomposable {
    var absolute: TestScalar { TestScalar(Swift.abs(value)) }
}

extension TestScalar: AdditiveMonoid {
    static func + (lhs: TestScalar, rhs: TestScalar) -> TestScalar {
        TestScalar(lhs.value + rhs.value)
    }
}

extension TestScalar: AdditiveGroup {}
extension TestScalar: CommutativeAdditiveMonoid {}
extension TestScalar: CommutativeAdditiveGroup {}

extension TestScalar: MultiplicativeMonoid {
    static func * (lhs: TestScalar, rhs: TestScalar) -> TestScalar {
        TestScalar(lhs.value * rhs.value)
    }
}

extension TestScalar: MultiplicativeMonoidWithInverse {
    var reciprocal: Result<TestScalar, AlgebraError.DivisionByZero> {
        guard !isZero else { return .failure(.init()) }
        return .success(TestScalar(1.0 / value))
    }
}

extension TestScalar: CommutativeMultiplicativeMonoid {}
extension TestScalar: CommutativeMultiplicativeMonoidWithInverse {}

extension TestScalar: Scalable {
    typealias Scalar = Double
    func scaled(by scalar: NonZero<Double>) -> TestScalar {
        TestScalar(value * scalar.value)
    }
}

extension TestScalar: SummableMonoid {
    static func sum(_ values: NonEmptyArray<TestScalar>) -> TestScalar {
        TestScalar(values.reduce(+, initialTransform: { $0.value }).self)
    }
}

extension TestScalar: SummableGroup {}

extension TestScalar: ProductableMonoid {
    static func product(_ values: NonEmptyArray<TestScalar>) -> TestScalar {
        TestScalar(values.reduce(*, initialTransform: { $0.value }).self)
    }
}

extension TestScalar: ProductableMonoidWithInverse {}

extension TestScalar: DiscreteRaisable {
    func raised(to power: Int) -> Result<TestScalar, AlgebraError> {
        let result = Foundation.pow(absolute.value, Double(power))
        guard result.isFinite else { return .failure(.nonFiniteResult(.init())) }
        let signed: TestScalar = (signum == .negative && !power.isMultiple(of: 2))
            ? TestScalar(-result) : TestScalar(result)
        return .success(signed)
    }
}

extension TestScalar: SignedRaisable {
    func raised(to power: Double) -> Result<TestScalar, AlgebraError> {
        guard signum != .negative || power.truncatingRemainder(dividingBy: 1) == 0 else {
            return .failure(.incompatibleParameterPair(.init("negative base with fractional exponent")))
        }
        let result = Foundation.pow(absolute.value, power)
        guard result.isFinite else { return .failure(.nonFiniteResult(.init())) }
        return .success(TestScalar(result))
    }
}

/// NonZero<Double>-backed scalar for total multiplicative group.
struct TestNonZeroScalar: Equatable, Sendable {
    let wrapped: NonZero<Double>

    init(_ nz: NonZero<Double>) { self.wrapped = nz }
}

extension TestNonZeroScalar: OneContaining {
    static var one: TestNonZeroScalar { TestNonZeroScalar(.one) }
    var isOne: Bool { wrapped.value == 1 }
}

extension TestNonZeroScalar: MultiplicativeMonoid {
    static func * (lhs: TestNonZeroScalar, rhs: TestNonZeroScalar) -> TestNonZeroScalar {
        TestNonZeroScalar(NonZero(unchecked: lhs.wrapped.value * rhs.wrapped.value))
    }
}

extension TestNonZeroScalar: MultiplicativeGroup {
    var reciprocal: TestNonZeroScalar {
        TestNonZeroScalar(NonZero(unchecked: 1.0 / wrapped.value))
    }
}

extension TestNonZeroScalar: CommutativeMultiplicativeMonoid {}
extension TestNonZeroScalar: CommutativeMultiplicativeGroup {}

/// SummableMonoid where `sum` is primitive and `+` is derived.
struct TestSummable: Equatable, Sendable {
    let value: Double
    static var sumCallCount = 0

    init(_ value: Double) { self.value = value }
}

extension TestSummable: ZeroContaining {
    static var zero: TestSummable { TestSummable(0) }
    var isZero: Bool { value == 0 }
}

extension TestSummable: AdditiveMonoid {} // + derived from SummableMonoid below

extension TestSummable: AdditiveGroup {
    prefix static func - (operand: TestSummable) -> TestSummable {
        TestSummable(-operand.value)
    }
}

extension TestSummable: SummableMonoid {
    static func sum(_ values: NonEmptyArray<TestSummable>) -> TestSummable {
        sumCallCount += 1
        return TestSummable(values.reduce(+, initialTransform: { $0.value }))
    }
}

extension TestSummable: SummableGroup {}

/// ProductableMonoid where `product` is primitive and `*` is derived.
struct TestProductable: Equatable, Sendable {
    let value: Double
    static var productCallCount = 0

    init(_ value: Double) { self.value = value }
}

extension TestProductable: OneContaining {
    static var one: TestProductable { TestProductable(1) }
    var isOne: Bool { value == 1 }
}

extension TestProductable: MultiplicativeMonoid {} // * derived from ProductableMonoid below

extension TestProductable: ProductableMonoid {
    static func product(_ values: NonEmptyArray<TestProductable>) -> TestProductable {
        productCallCount += 1
        return TestProductable(values.reduce(*, initialTransform: { $0.value }))
    }
}

// MARK: - 1. Signum Tests

final class SignumTests: XCTestCase {
    func testFlipped() {
        XCTAssertEqual(Signum.negative.flipped, .positive)
        XCTAssertEqual(Signum.positive.flipped, .negative)
        XCTAssertEqual(Signum.zero.flipped, .zero)
    }

    func testRawValues() {
        XCTAssertEqual(Signum.negative.rawValue, -1)
        XCTAssertEqual(Signum.zero.rawValue, 0)
        XCTAssertEqual(Signum.positive.rawValue, 1)
    }

    func testCaseIterable() {
        XCTAssertEqual(Signum.allCases.count, 3)
    }
}

// MARK: - 2. Signed Protocol Tests

final class SignedTests: XCTestCase {
    func testPrefixMinusDispatchesToFlippedSign() {
        let x = TestScalar(5)
        XCTAssertEqual(-x, x.flippedSign)
    }

    func testDoubleNegation() {
        let x = TestScalar(7)
        XCTAssertEqual(-(-x), x)
    }

    func testIsPositiveIsNegative() {
        XCTAssertTrue(TestScalar(3).isPositive)
        XCTAssertFalse(TestScalar(3).isNegative)
        XCTAssertTrue(TestScalar(-2).isNegative)
        XCTAssertFalse(TestScalar(-2).isPositive)
        XCTAssertFalse(TestScalar(0).isPositive)
        XCTAssertFalse(TestScalar(0).isNegative)
    }
}

// MARK: - 3. AbsoluteValueDecomposable Tests

final class AbsoluteValueTests: XCTestCase {
    func testAbsoluteOfPositive() {
        XCTAssertEqual(TestScalar(5).absolute, TestScalar(5))
    }

    func testAbsoluteOfNegative() {
        XCTAssertEqual(TestScalar(-3).absolute, TestScalar(3))
    }

    func testAbsoluteOfZero() {
        XCTAssertEqual(TestScalar(0).absolute, TestScalar(0))
    }
}

// MARK: - 4. ZeroContaining / OneContaining Tests

final class ZeroOneTests: XCTestCase {
    func testZeroIsZero() {
        XCTAssertTrue(TestScalar.zero.isZero)
    }

    func testNonZeroIsNotZero() {
        XCTAssertFalse(TestScalar(5).isZero)
    }

    func testOneIsOne() {
        XCTAssertTrue(TestScalar.one.isOne)
    }

    func testNonOneIsNotOne() {
        XCTAssertFalse(TestScalar(5).isOne)
    }
}

// MARK: - 5. NonZero Tests

final class NonZeroTests: XCTestCase {
    func testInitZeroReturnsNil() {
        XCTAssertNil(NonZero<Double>(0))
    }

    func testInitNonZeroSucceeds() {
        let nz = NonZero<Double>(5)
        XCTAssertNotNil(nz)
        XCTAssertEqual(nz?.value, 5)
    }

    func testInitInfinityReturnsNil() {
        XCTAssertNil(NonZero<Double>(.infinity))
    }

    func testInitNaNReturnsNil() {
        XCTAssertNil(NonZero<Double>(.nan))
    }

    func testOneConstant() {
        XCTAssertEqual(NonZero<Double>.one.value, 1)
    }

    func testNegativeOneConstant() {
        XCTAssertEqual(NonZero<Double>.negativeOne.value, -1)
    }

    func testEquatable() {
        XCTAssertEqual(NonZero<Double>(3), NonZero<Double>(3))
        XCTAssertNotEqual(NonZero<Double>(3), NonZero<Double>(4))
    }

    func testHashable() {
        let a = NonZero<Double>(3)!
        let b = NonZero<Double>(3)!
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testMultiplicationTxNonZero() {
        let nz = NonZero<Double>(2)!
        XCTAssertEqual(3.0 * nz, 6.0)
    }

    func testMultiplicationNonZeroXt() {
        let nz = NonZero<Double>(2)!
        XCTAssertEqual(nz * 3.0, 6.0)
    }

    func testDivisionByNonZero() {
        let nz = NonZero<Double>(2)!
        XCTAssertEqual(6.0 / nz, 3.0)
    }

    func testInitIntegerZeroReturnsNil() {
        XCTAssertNil(NonZero<Int>(0))
    }

    func testInitIntegerNonZeroSucceeds() {
        XCTAssertNotNil(NonZero<Int>(5))
    }
}

// MARK: - 6. NonEmptyArray Tests

final class NonEmptyArrayTests: XCTestCase {
    func testInitEmptyArrayReturnsNil() {
        XCTAssertNil(NonEmptyArray<Int>([]))
    }

    func testInitNonEmptyArray() {
        let nea = NonEmptyArray([1, 2, 3])!
        XCTAssertEqual(nea.head, 1)
        XCTAssertEqual(nea.tail, [2, 3])
    }

    func testHeadTailInit() {
        let nea = NonEmptyArray(10, [20, 30])
        XCTAssertEqual(nea.head, 10)
        XCTAssertEqual(nea.tail, [20, 30])
    }

    func testArrayRoundTrip() {
        let arr = [1, 2, 3]
        let nea = NonEmptyArray(arr)!
        XCTAssertEqual(nea.array, arr)
    }

    func testCount() {
        XCTAssertEqual(NonEmptyArray(1, [2, 3]).count, 3)
        XCTAssertEqual(NonEmptyArray(1, []).count, 1)
    }

    func testMap() {
        let nea = NonEmptyArray(1, [2, 3])
        let mapped = nea.map { $0 * 10 }
        XCTAssertEqual(mapped.array, [10, 20, 30])
    }

    func testReduce() {
        let nea = NonEmptyArray(1, [2, 3])
        let result = nea.reduce(+, initialTransform: { $0 })
        XCTAssertEqual(result, 6)
    }

    func testRandomAccessCollection() {
        let nea = NonEmptyArray(10, [20, 30])
        XCTAssertEqual(nea[0], 10)
        XCTAssertEqual(nea[1], 20)
        XCTAssertEqual(nea[2], 30)
        XCTAssertEqual(Array(nea), [10, 20, 30])
    }

    func testEquatable() {
        let a = NonEmptyArray(1, [2])
        let b = NonEmptyArray(1, [2])
        let c = NonEmptyArray(1, [3])
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testHashable() {
        let a = NonEmptyArray(1, [2])
        let b = NonEmptyArray(1, [2])
        XCTAssertEqual(a.hashValue, b.hashValue)
    }
}

// MARK: - 7. AdditiveMonoid Defaults

final class AdditiveMonoidTests: XCTestCase {
    func testDefaultSumOverNonEmptyArray() {
        let vals = NonEmptyArray(TestScalar(1), [TestScalar(2), TestScalar(3)])
        let result = TestScalar.sum(vals)
        XCTAssertEqual(result, TestScalar(6))
    }

    func testAdditiveIdentity() {
        let x = TestScalar(42)
        XCTAssertEqual(x + .zero, x)
        XCTAssertEqual(.zero + x, x)
    }
}

// MARK: - 8. AdditiveGroup Defaults

final class AdditiveGroupTests: XCTestCase {
    func testBinaryMinusDerived() {
        let a = TestScalar(10)
        let b = TestScalar(3)
        XCTAssertEqual(a - b, TestScalar(7))
    }

    func testInverse() {
        let x = TestScalar(5)
        XCTAssertEqual(x + (-x), .zero)
    }
}

// MARK: - 9. SummableMonoid Reverse Derivation

final class SummableMonoidTests: XCTestCase {
    func testBinaryPlusDerivedFromSum() {
        TestSummable.sumCallCount = 0
        let a = TestSummable(3)
        let b = TestSummable(4)
        let result = a + b
        XCTAssertEqual(result, TestSummable(7))
        XCTAssertEqual(TestSummable.sumCallCount, 1)
    }
}

// MARK: - 10. MultiplicativeMonoid

final class MultiplicativeMonoidTests: XCTestCase {
    func testMultiplicativeIdentity() {
        let x = TestScalar(7)
        XCTAssertEqual(x * .one, x)
        XCTAssertEqual(.one * x, x)
    }
}

// MARK: - 11. MultiplicativeMonoidWithInverse

final class MultiplicativeMonoidWithInverseTests: XCTestCase {
    func testReciprocalNonZero() {
        let x = TestScalar(4)
        let recip = try! x.reciprocal.get()
        XCTAssertEqual(recip, TestScalar(0.25))
    }

    func testReciprocalZeroFails() {
        let x = TestScalar(0)
        switch x.reciprocal {
        case .success:
            XCTFail("Expected failure for zero reciprocal")
        case .failure:
            break
        }
    }

    func testDividingByDerived() {
        let a = TestScalar(10)
        let b = TestScalar(4)
        let result = try! a.dividing(by: b).get()
        XCTAssertEqual(result.value, 2.5, accuracy: 1e-10)
    }

    func testDividingByZeroFails() {
        let a = TestScalar(10)
        switch a.dividing(by: .zero) {
        case .success:
            XCTFail("Expected failure dividing by zero")
        case .failure:
            break
        }
    }

    func testReciprocalOrNil() {
        XCTAssertNotNil(TestScalar(5).reciprocalOrNil)
        XCTAssertNil(TestScalar(0).reciprocalOrNil)
    }

    func testDividingOrNil() {
        XCTAssertNotNil(TestScalar(10).dividingOrNil(by: TestScalar(2)))
        XCTAssertNil(TestScalar(10).dividingOrNil(by: .zero))
    }
}

// MARK: - 12. MultiplicativeGroup (Total Inverse)

final class MultiplicativeGroupTests: XCTestCase {
    func testTotalReciprocal() {
        let x = TestNonZeroScalar(NonZero(2.0)!)
        let recip = x.reciprocal
        XCTAssertEqual(recip.wrapped.value, 0.5, accuracy: 1e-10)
    }

    func testDivisionDerived() {
        let a = TestNonZeroScalar(NonZero(6.0)!)
        let b = TestNonZeroScalar(NonZero(3.0)!)
        let result = a / b
        XCTAssertEqual(result.wrapped.value, 2.0, accuracy: 1e-10)
    }
}

// MARK: - 13. ProductableMonoid Reverse Derivation

final class ProductableMonoidTests: XCTestCase {
    func testBinaryStarDerivedFromProduct() {
        TestProductable.productCallCount = 0
        let a = TestProductable(3)
        let b = TestProductable(4)
        let result = a * b
        XCTAssertEqual(result, TestProductable(12))
        XCTAssertEqual(TestProductable.productCallCount, 1)
    }
}

// MARK: - 14. Scalable

final class ScalableTests: XCTestCase {
    func testScaledByOne() {
        let x = TestScalar(5)
        XCTAssertEqual(x.scaled(by: .one), x)
    }

    func testScaledByArbitraryValue() {
        let x = TestScalar(3)
        let nz = NonZero<Double>(2)!
        XCTAssertEqual(x.scaled(by: nz), TestScalar(6))
    }

    func testScaledOne() {
        let nz = NonZero<Double>(5)!
        let result = TestScalar.scaledOne(nz)
        XCTAssertEqual(result, TestScalar(5))
    }
}

// MARK: - 15. Array / NonEmptyArray Extensions

final class ArrayExtensionTests: XCTestCase {

    // Sum
    func testArraySumEmpty() {
        let empty: [TestScalar] = []
        switch empty.sum() {
        case .success:
            XCTFail("Expected failure for empty sum")
        case .failure:
            break
        }
    }

    func testArraySumNonEmpty() {
        let arr: [TestScalar] = [TestScalar(1), TestScalar(2), TestScalar(3)]
        let result = try! arr.sum().get()
        XCTAssertEqual(result, TestScalar(6))
    }

    func testNonEmptyArraySum() {
        let nea = NonEmptyArray(TestScalar(1), [TestScalar(2), TestScalar(3)])
        XCTAssertEqual(nea.sum(), TestScalar(6))
    }

    // Mean
    func testNonEmptyArrayMean() {
        let nea = NonEmptyArray(TestScalar(2), [TestScalar(4), TestScalar(6)])
        let mean = nea.mean()
        XCTAssertEqual(mean.value, 4.0, accuracy: 1e-10)
    }

    // Product
    func testArrayProductEmpty() {
        let empty: [TestProductable] = []
        switch empty.product() {
        case .success:
            XCTFail("Expected failure for empty product")
        case .failure:
            break
        }
    }

    func testArrayProductNonEmpty() {
        let arr = [TestProductable(2), TestProductable(3), TestProductable(4)]
        let result = try! arr.product().get()
        XCTAssertEqual(result, TestProductable(24))
    }

    func testNonEmptyArrayProduct() {
        let nea = NonEmptyArray(TestProductable(2), [TestProductable(3)])
        XCTAssertEqual(nea.product(), TestProductable(6))
    }

    // Absolutes
    func testAbsolutes() {
        let arr = [TestScalar(-1), TestScalar(2), TestScalar(-3)]
        XCTAssertEqual(arr.absolutes, [TestScalar(1), TestScalar(2), TestScalar(3)])
    }
}

// MARK: - 16. AlgebraError Tests

final class AlgebraErrorTests: XCTestCase {
    func testDivisionByZeroWithoutContext() {
        let err = AlgebraError.DivisionByZero()
        XCTAssertNil(err.context)
    }

    func testDivisionByZeroWithContext() {
        let err = AlgebraError.DivisionByZero("test context")
        XCTAssertEqual(err.context, "test context")
    }

    func testAsAlgebraErrorLifts() {
        let err = AlgebraError.DivisionByZero("ctx")
        XCTAssertEqual(err.asAlgebraError, .divisionByZero(err))
    }

    func testMapToAlgebraError() {
        let result: Result<Int, AlgebraError.DivisionByZero> = .failure(.init("ctx"))
        let mapped = result.mapToAlgebraError()
        switch mapped {
        case .failure(let e):
            XCTAssertEqual(e, .divisionByZero(.init("ctx")))
        case .success:
            XCTFail("Expected failure")
        }
    }

    func testEquatableSameContext() {
        let a = AlgebraError.DivisionByZero("x")
        let b = AlgebraError.DivisionByZero("x")
        XCTAssertEqual(a, b)
    }

    func testEquatableDifferentContext() {
        let a = AlgebraError.DivisionByZero("x")
        let b = AlgebraError.DivisionByZero("y")
        XCTAssertNotEqual(a, b)
    }

    func testAllErrorVariants() {
        _ = AlgebraError.EmptyCollection("e").asAlgebraError
        _ = AlgebraError.InvalidScale("s").asAlgebraError
        _ = AlgebraError.NonFiniteResult("n").asAlgebraError
        _ = AlgebraError.IncompatibleParameterPair("p").asAlgebraError
    }

    func testIncompatibleParameterPairLifts() {
        let err = AlgebraError.IncompatibleParameterPair("test")
        XCTAssertEqual(err.asAlgebraError, .incompatibleParameterPair(err))
    }

    func testIncompatibleParameterPairMapToAlgebraError() {
        let result: Result<Int, AlgebraError.IncompatibleParameterPair> = .failure(.init("ctx"))
        let mapped = result.mapToAlgebraError()
        switch mapped {
        case .failure(let e):
            XCTAssertEqual(e, .incompatibleParameterPair(.init("ctx")))
        case .success:
            XCTFail("Expected failure")
        }
    }
}

// MARK: - 17. SignedRaisable Tests

final class SignedRaisableTests: XCTestCase {
    func testPositiveBaseEvenPower() {
        let x = TestScalar(3)
        let result = try! x.raised(to: 2).get()
        XCTAssertEqual(result.value, 9.0, accuracy: 1e-10)
        XCTAssertTrue(result.isPositive)
    }

    func testPositiveBaseOddPower() {
        let x = TestScalar(2)
        let result = try! x.raised(to: 3).get()
        XCTAssertEqual(result.value, 8.0, accuracy: 1e-10)
        XCTAssertTrue(result.isPositive)
    }

    func testNegativeBaseEvenPower() {
        let x = TestScalar(-3)
        let result = try! x.raised(to: 2).get()
        XCTAssertEqual(result.value, 9.0, accuracy: 1e-10)
    }

    func testNegativeBaseOddPower() {
        let x = TestScalar(-2)
        let result = try! x.raised(to: 3).get()
        XCTAssertEqual(result.value, -8.0, accuracy: 1e-10)
    }

    func testRaisedToScalarPower() {
        let x = TestScalar(4)
        let result = try! x.raised(to: 0.5).get()
        XCTAssertEqual(result.value, 2.0, accuracy: 1e-10)
    }

    func testNegativeBaseFractionalPowerFails() {
        let x = TestScalar(-4)
        switch x.raised(to: 0.5) {
        case .success:
            XCTFail("Expected failure for negative base with fractional exponent")
        case .failure(let e):
            if case .incompatibleParameterPair = e {} else {
                XCTFail("Expected incompatibleParameterPair, got \(e)")
            }
        }
    }

    func testNegativeBaseIntegerPowerViaScalarSucceeds() {
        let x = TestScalar(-3)
        let result = try! x.raised(to: 2.0).get()
        XCTAssertEqual(result.value, 9.0, accuracy: 1e-10)
    }
}
