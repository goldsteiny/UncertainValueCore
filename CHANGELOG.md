# Changelog

## Unreleased

### New Modules
- Added MultiplicativeUncertainValue module (log-domain multiplicative uncertainty).
- Added UncertainValueStatistics module (arithmetic/geometric means and standard deviation helpers).
- Added UncertainValueCoreAlgebra package for algebra protocols; UncertainValue and MultiplicativeUncertainValue now conform to and build on these protocols.

### New Features
- Added `BoundsProviding` protocol with `lowerBound`, `upperBound`, and `bounds: ClosedRange<Scalar>` properties for displaying confidence intervals/error bars in UIs.
  - Conditional default implementations for `AbsoluteErrorProviding` (additive: value ± absoluteError).
  - Conditional default implementations for `MultiplicativeErrorProviding` (multiplicative: value */ multiplicativeError, handles negative values correctly).
  - `UncertainValue` and `MultiplicativeUncertainValue` now conform to `BoundsProviding`.

### Breaking Changes

#### API Renames
- Renamed MeasurementMath to UncertainValueMath.
- MultiplicativeUncertainValue: `.sign` property renamed to `.signum`, now uses `Signum` enum (`.positive`, `.negative`, `.zero`) instead of `FloatingPointSign` (`.plus`, `.minus`).
- `Array<FloatingPointSign>.product()` replaced with `Array<Signum>.product()`.

#### Throwing Behavior (nil → throws)
- `UncertainValue.asMultiplicative` now throws instead of returning `nil`.
- `MultiplicativeUncertainValue.init(value:multiplicativeError:)` now throws for invalid inputs.
- `MultiplicativeUncertainValue.init(logAbs:signum:)` now throws for non-finite values.
- `MultiplicativeUncertainValue.exp(_:withResultSign:)` now throws instead of being non-throwing.
- `scaledUp(by:)` and `scaledDown(by:)` throw for zero or non-finite scalars.
- `raised(to:)` throws instead of returning `nil` for invalid inputs.
- Scalar operators (`*`, `/` with Double) now throw instead of returning optionals.

### Internal Improvements
- MultiplicativeUncertainValue restructured: consolidated from 5 files into 3 (main + Conversions + Operators).
- Protocol-driven defaults: `reciprocal`, `dividing(by:using:)`, `scaledDown(by:)` now use protocol default implementations.
- Added `Signum.flipped` property.
- Tests migrated from XCTest to Swift Testing framework.

## 1.0.0 - Initial public release
- Initial release of UncertainValueCore and related modules.
