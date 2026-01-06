# Architecture Overview - UncertainValueCore

This package provides primitives for arithmetic with measurement uncertainty. It is Apple-only and uses Accelerate for statistics where available.

## Modules and Dependencies

- UncertainValueCoreAlgebra
  - Algebraic protocol surface and shared primitives
  - NormStrategy and pure norm functions (norm1/norm2/normp)
- UncertainValueCore
  - Core data types (UncertainValue)
  - UncertainValueMath and array helpers
  - Array extensions for aggregation
- UncertainValueConvenience
  - L2-only operator overloads for ergonomic syntax
  - Depends on UncertainValueCore and UncertainValueCoreAlgebra
- MultiplicativeUncertainValue
  - Log-domain representation for multiplicative uncertainty
  - Depends on UncertainValueCore and UncertainValueCoreAlgebra
- UncertainValueStatistics
  - Arithmetic mean, geometric mean, standard deviation helpers (L2)
  - Depends on UncertainValueCore and MultiplicativeUncertainValue
  - Uses Accelerate (vDSP) for optimized implementations

## Core Types

### UncertainValue
- Represents value ± absoluteError (1-sigma)
- Derived metrics:
  - relativeError = absoluteError / |value|
  - variance = absoluteError^2

### NormStrategy (UncertainValueCoreAlgebra)
- Defines how independent errors are combined (L1, L2, Lp)
- Used in multi-input operations (sum, product, means)

### MultiplicativeUncertainValue
- Log-domain model: value = sign * exp(logAbs.value)
- Error stored in log space (logAbs.absoluteError)
- Provides conversions to/from UncertainValue

## UncertainValueMath
- Pure functions for log/exp/sin/cos and multi-input functions
- Invalid domains return nil (e.g., log for non-positive values)
- Multi-input functions require explicit NormStrategy

## Error Propagation Model
- Uncertainties are treated as independent
- L2 corresponds to standard Gaussian error propagation
- L1 is conservative (linear accumulation)
- Lp provides a tunable interpolation

## Performance
- Accelerate (vDSP) used for statistics (mean, standard deviation)
- Norm implementations use scaling to avoid overflow/underflow

## Public API Policy
- Core APIs favor explicit norm strategies
- Convenience module provides L2-only operators
- Unsafe preconditions are being removed per quality plan
