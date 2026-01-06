# Public API Boundaries - UncertainValueCore

This document defines the intended public API surface and the error-handling contract for the package.

## Stable Modules

- UncertainValueCoreAlgebra
  - Algebra protocols and base structures
  - Public types: NormStrategy
  - Public functions: norm1, norm2, normp, norm
- UncertainValueCore
  - Public types: UncertainValue, UncertainValueMath
  - Array extensions for [UncertainValue] and [Double]
- UncertainValueConvenience
  - Operator overloads for UncertainValue using L2
- MultiplicativeUncertainValue
  - MultiplicativeUncertainValue type and conversions
- UncertainValueStatistics
  - Arithmetic and geometric mean, standard deviation helpers

## Error Handling Contract (Target)

- Public APIs should never crash on invalid inputs.
- Invalid inputs should be handled by:
  - returning nil for domain errors (e.g., log of non-positive values), or
  - throwing typed errors for validation failures.
- Preconditions are reserved for internal invariants only.

## Operator Policy

- Core APIs favor explicit NormStrategy methods (no operators).
- Convenience module provides L2-only operators for ergonomic usage.
- Global operators should live in UncertainValueConvenience to avoid client conflicts.

## Access Control Guidelines

- Keep helpers internal unless they are part of the documented public API.
- Prefer public APIs that are explicit about norms and failure behavior.
- Avoid exposing internal math utilities unless they are stable and documented.

## Compatibility

- Semver is used for releases.
- Breaking changes are documented in CHANGELOG.md.
