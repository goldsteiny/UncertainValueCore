import Foundation
import Testing
@testable import UncertainValueBinning

struct CountObservationModelCodingTests {

    // MARK: - validatedMultinomial factory

    @Test func validatedMultinomialRejectsZero() {
        #expect(CountObservationModel.validatedMultinomial(allocatedCount: 0) == nil)
    }

    @Test func validatedMultinomialRejectsNegative() {
        #expect(CountObservationModel.validatedMultinomial(allocatedCount: -5) == nil)
    }

    @Test func validatedMultinomialRejectsMinInt() {
        #expect(CountObservationModel.validatedMultinomial(allocatedCount: Int.min) == nil)
    }

    @Test func validatedMultinomialAcceptsOne() {
        let model = CountObservationModel.validatedMultinomial(allocatedCount: 1)
        #expect(model == .multinomial(allocatedCount: 1))
    }

    @Test func validatedMultinomialAcceptsPositive() {
        let model = CountObservationModel.validatedMultinomial(allocatedCount: 42)
        #expect(model == .multinomial(allocatedCount: 42))
    }

    @Test func validatedMultinomialAcceptsLargeCount() {
        let model = CountObservationModel.validatedMultinomial(allocatedCount: 1_000_000)
        #expect(model != nil)
    }

    // MARK: - Equatable

    @Test func poissonEqualsSelf() {
        #expect(CountObservationModel.poisson == .poisson)
    }

    @Test func poissonNotEqualsMultinomial() {
        #expect(CountObservationModel.poisson != .multinomial(allocatedCount: 1))
    }

    @Test func multinomialsWithSameCountAreEqual() {
        #expect(CountObservationModel.multinomial(allocatedCount: 42) == .multinomial(allocatedCount: 42))
    }

    @Test func multinomialsWithDifferentCountsAreNotEqual() {
        #expect(CountObservationModel.multinomial(allocatedCount: 10) != .multinomial(allocatedCount: 20))
    }

    // MARK: - Hashable

    @Test func poissonHashConsistency() {
        let a = CountObservationModel.poisson
        let b = CountObservationModel.poisson
        #expect(a.hashValue == b.hashValue)
    }

    @Test func multinomialHashConsistency() {
        let a = CountObservationModel.multinomial(allocatedCount: 42)
        let b = CountObservationModel.multinomial(allocatedCount: 42)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func canBeUsedInSet() {
        let s: Set<CountObservationModel> = [.poisson, .poisson, .multinomial(allocatedCount: 10)]
        #expect(s.count == 2)
    }

    // MARK: - Codable round-trips

    @Test func poissonRoundTrips() throws {
        let model = CountObservationModel.poisson
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(CountObservationModel.self, from: data)
        #expect(decoded == model)
    }

    @Test func multinomialRoundTrips() throws {
        let model = CountObservationModel.multinomial(allocatedCount: 42)
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(CountObservationModel.self, from: data)
        #expect(decoded == model)
    }

    @Test func multinomialRoundTripsWithLargeCount() throws {
        let model = CountObservationModel.multinomial(allocatedCount: 999_999)
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(CountObservationModel.self, from: data)
        #expect(decoded == model)
    }

    // MARK: - JSON shape is explicit (not synthesized)

    @Test func poissonEncodesOnlyRegimeKey() throws {
        let data = try JSONEncoder().encode(CountObservationModel.poisson)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["regime"] as? String == "poisson")
        #expect(json.keys.count == 1)
        #expect(json["allocatedCount"] == nil)
    }

    @Test func multinomialEncodesRegimeAndAllocatedCountKeys() throws {
        let data = try JSONEncoder().encode(CountObservationModel.multinomial(allocatedCount: 7))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["regime"] as? String == "multinomial")
        #expect(json["allocatedCount"] as? Int == 7)
        #expect(json.keys.count == 2)
    }

    @Test func jsonShapeIsNotSynthesized() throws {
        // Synthesized encoding would produce {"_0": 42} for the multinomial case.
        // Explicit encoding must produce {"regime": "multinomial", "allocatedCount": 42}.
        let data = try JSONEncoder().encode(CountObservationModel.multinomial(allocatedCount: 42))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["_0"] == nil)
        #expect(json["regime"] != nil)
    }

    // MARK: - Decoder validates scalar invariants

    @Test func decoderRejectsNegativeAllocatedCount() throws {
        let json = #"{"regime":"multinomial","allocatedCount":-1}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CountObservationModel.self, from: json)
        }
    }

    @Test func decoderRejectsZeroAllocatedCount() throws {
        let json = #"{"regime":"multinomial","allocatedCount":0}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CountObservationModel.self, from: json)
        }
    }

    @Test func decoderRejectsUnknownRegime() throws {
        let json = #"{"regime":"gamma"}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CountObservationModel.self, from: json)
        }
    }

    @Test func decoderRejectsMissingRegimeKey() throws {
        let json = #"{"allocatedCount":10}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(CountObservationModel.self, from: json)
        }
    }

    @Test func decoderAcceptsPoisson() throws {
        let json = #"{"regime":"poisson"}"#.data(using: .utf8)!
        let model = try JSONDecoder().decode(CountObservationModel.self, from: json)
        #expect(model == .poisson)
    }

    @Test func decoderAcceptsValidMultinomial() throws {
        let json = #"{"regime":"multinomial","allocatedCount":100}"#.data(using: .utf8)!
        let model = try JSONDecoder().decode(CountObservationModel.self, from: json)
        #expect(model == .multinomial(allocatedCount: 100))
    }
}
