# Quality Plan 202601 - UncertainValueCore (Apple-only)

## Goals
- Keep the package Apple-only and take advantage of Apple frameworks (Accelerate, Darwin).
- Make public APIs consistent, predictable, and safe for open-source consumers.
- Replace crashy preconditions with explicit errors or safe fallbacks.
- Reduce duplication by leveraging Swift protocols, generic constraints, and extensions.
- Improve documentation, public API boundaries, and testing coverage.

## Constraints
- Apple-only platforms (iOS/macOS). No Linux support needed.
- Swift 5.9+ and modern Swift patterns (Sendable, value semantics, protocol extensions).

## Current Findings (Bad Patterns and Risks)
- Inconsistent error handling: some APIs return nil, others call precondition.
  - Examples: statistics functions precondition on array size.
  - Files: Sources/UncertainValueStatistics/Array+ArithmeticMean.swift, Array+GeometricMean.swift, Array+SampleStandardDeviation.swift
- Public API crashes on invalid inputs (precondition usage).
  - Files: Sources/MultiplicativeUncertainValue/MultiplicativeUncertainValue.swift, MultiplicativeUncertainValue+Arithmetic.swift
- Duplicated logic across additive and multiplicative types (operators, list operations, conversions).
  - Files: Sources/UncertainValueCore/UncertainValue+Lists.swift, Sources/MultiplicativeUncertainValue/MultiplicativeUncertainValue+Lists.swift
- Global operator ** defined in Core can conflict in client code.
  - File: Sources/UncertainValueCore/UncertainValue+Exponentiation.swift
- Statistics module hardcodes L2 behavior without explicit naming consistency.
  - Files: Sources/UncertainValueStatistics/*
- Mixed test frameworks (Testing vs XCTest).
  - Tests/UncertainValueCoreTests (Testing), Tests/UncertainValueStatisticsTests (XCTest)
- Public API surface is broad; access control not consistently minimized.
  - Example: global norm functions are public by default.

## Design Direction (Swift-first refactors)
- Introduce protocol-based shared behavior for multiplicative and additive operations to reduce duplication.
- Prefer value types (struct) unless identity or reference semantics are required.
- Use protocol extensions and generic Array extensions to implement shared list operations once.
- Avoid naming conflicts with stdlib protocols (do not use MultiplicativeArithmetic).

## Protocol Design Proposal (Session 2 anchor)
Goal: Build shared surfaces for multiplicative and additive operations, then migrate UncertainValue and MultiplicativeUncertainValue to rely on protocol defaults where possible.

Proposed multiplicative protocol (name and exact signature to finalize in Session 2):

```
public protocol UncertainMultiplicative: Sendable {
    associatedtype Scalar: BinaryFloatingPoint

    static var one: Self { get }

    func multiplying(_ other: Self, using strategy: NormStrategy) -> Self
    var reciprocal: Self? { get }
    func raised(to power: Scalar) -> Self?
}

public extension UncertainMultiplicative {
    func dividing(by other: Self, using strategy: NormStrategy) -> Self? {
        other.reciprocal?.multiplying(self, using: strategy)
    }
}

public extension Array where Element: UncertainMultiplicative {
    func product(using strategy: NormStrategy) -> Element {
        reduce(.one) { $0.multiplying($1, using: strategy) }
    }
}
```

Proposed additive protocol (name and exact signature to finalize in Session 2):

```
public protocol UncertainAdditive: Sendable {
    associatedtype Scalar: BinaryFloatingPoint

    static var zero: Self { get }

    func adding(_ other: Self, using strategy: NormStrategy) -> Self
    var negative: Self { get }
}

public extension UncertainAdditive {
    func subtracting(_ other: Self, using strategy: NormStrategy) -> Self {
        adding(other.negative, using: strategy)
    }
}

public extension Array where Element: UncertainAdditive {
    func sum(using strategy: NormStrategy) -> Element {
        reduce(.zero) { $0.adding($1, using: strategy) }
    }
}
```

Notes:
- Optional reciprocal allows UncertainValue to return nil for zero, while MultiplicativeUncertainValue may always succeed.
- Additive and multiplicative protocols are intentionally separate to avoid over-constraining types.
- Array sum/product via reduce should be tested against current implementations to preserve numerical behavior.
- Conformance targets: UncertainValue (both additive and multiplicative), MultiplicativeUncertainValue (multiplicative).
- Use @inlinable for protocol defaults that are part of the public API.

## Coverage Map
- Sources/UncertainValueCore: Sessions 2-5
- Sources/UncertainValueConvenience: Session 6
- Sources/MultiplicativeUncertainValue: Sessions 2-3
- Sources/UncertainValueStatistics: Session 7
- Tests/*: Sessions 8-9
- Package.swift, README.md, docs/: Session 1 and Session 9

## Session Plan (9 sessions, 2-4 diffs each)

### Session 1 - Apple-only Posture and API Audit
Scope: Package.swift, README.md, docs/
Diffs:
1) Update README to explicitly state Apple-only support and Accelerate dependency.
2) Add docs/architecture.md and docs/public_api.md defining intended API boundaries and error signaling.
3) Add CONTRIBUTING.md and a minimal CHANGELOG.md (semver expectations).
Exit criteria:
- Apple-only stance is documented.
- Public API boundaries and failure modes are documented.

### Session 2 - Protocol Foundation (Additive + Multiplicative)
Scope: Sources/UncertainValueCore/ (new protocols), Sources/MultiplicativeUncertainValue/
Diffs:
1) Finalize and introduce UncertainMultiplicative and UncertainAdditive protocols and default implementations.
2) Add Array extensions for sum(using:) and product(using:), plus derived helpers (subtracting/dividing).
3) Conform UncertainValue and MultiplicativeUncertainValue; remove duplicated list-ops where possible.
Tests:
- Add tests for protocol-derived behavior (same results as existing concrete implementations).
Exit criteria:
- Shared additive/multiplicative behavior is implemented once via protocol extensions.

### Session 3 - MultiplicativeUncertainValue Refactor
Scope: Sources/MultiplicativeUncertainValue/*
Diffs:
1) Decide struct vs class and align with value semantics if possible.
2) Replace preconditions with throwing or failable initializers and explicit error types.
3) Remove duplicated operators and list operations in favor of protocol defaults.
Tests:
- Extend MultiplicativeUncertainValueTests for invalid inputs and conversion round-trips.
Exit criteria:
- No preconditions in public APIs.
- MultiplicativeUncertainValue uses shared protocol behavior.

### Session 4 - Core Error Handling and Protocol Reliance
Scope: Sources/UncertainValueCore/UncertainValue.swift, UncertainValue+Arithmetic.swift, UncertainValue+Lists.swift
Diffs:
1) Introduce UncertainValueError (invalidValue, nonFinite, divisionByZero, invalidExponent, invalidNorm).
2) Add safe initializers (init(validating:) throws, init?(...) returning nil) and document which APIs throw vs return nil.
3) Migrate UncertainValue list operations to rely on additive/multiplicative protocols where possible.
Tests:
- Update UncertainValueTests for error cases and NaN/inf handling.
Exit criteria:
- Public API uses a consistent error model.
- UncertainValue relies on protocol defaults for shared behavior.

### Session 5 - Norm Strategy and Numerical Robustness
Scope: Sources/UncertainValueCore/NormStrategy.swift
Diffs:
1) Validate NormStrategy.lp(p) (p > 0, finite) and define behavior for invalid p.
2) Add explicit handling for non-finite inputs (NaN/inf) in norm functions.
3) Add documentation for numerical stability and performance tradeoffs.
Tests:
- Extend NormTests for invalid p, NaN, inf.
Exit criteria:
- Norm functions behave deterministically for invalid inputs and are documented.

### Session 6 - Convenience Operators and Exponentiation
Scope: Sources/UncertainValueConvenience, UncertainValue+Exponentiation.swift
Diffs:
1) Move ** operator to Convenience module (avoid global operator conflicts in Core).
2) Ensure convenience operators are clearly labeled as L2-only in docs.
3) Add tests for operator precedence and invalid exponent handling.
Exit criteria:
- Operators are isolated to the convenience module.

### Session 7 - Statistics Module Overhaul (Apple-only)
Scope: Sources/UncertainValueStatistics/*
Diffs:
1) Replace preconditions with safe errors or optional return variants.
2) Add strategy parameters where appropriate (avoid hardcoded L2 unless explicitly named L2).
3) Keep Accelerate usage (Apple-only), but make behavior explicit in docs.
Tests:
- Expand UncertainValueStatisticsTests for invalid inputs and non-finite values.
Exit criteria:
- Statistics APIs are safe, explicit about norm strategy, and documented.

### Session 8 - Test Framework Consistency and Coverage
Scope: Tests/*
Diffs:
1) Standardize on one test framework (Testing or XCTest) and migrate remaining tests.
2) Add tests for invalid inputs (NaN/inf), negative values where disallowed, and extreme-value stability.
3) Add property-based test helpers for key invariants (commutativity, scaling, error bounds).
Exit criteria:
- Tests are uniform and cover invalid and extreme inputs.

### Session 9 - Packaging, CI, and Documentation Finalization
Scope: Package.swift, README.md, docs/, Tests
Diffs:
1) Add GitHub Actions CI (macOS build + tests).
2) Add DocC bundle and publish instructions (or a simple docs generation script).
3) Final audit: public API access control, deprecated APIs, and semantic versioning notes.
Exit criteria:
- CI passes and documentation is buildable locally.

## Success Metrics
- No public API crashes via precondition; invalid inputs are handled via errors or documented optional returns.
- Shared additive and multiplicative behavior is defined once via protocol extensions.
- Operators that can conflict are isolated to the Convenience module.
- Tests cover invalid inputs, NaN/inf, and extreme values.
- Documentation explains norm strategies, error propagation formulas, and module boundaries.
