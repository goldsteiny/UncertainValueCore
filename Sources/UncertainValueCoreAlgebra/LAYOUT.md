# UncertainValueCoreAlgebra Layout

This target is organized by algebra domain concepts instead of Swift construct kinds (`Protocols`/`Extensions`/`Types`).

## Directories

- `Algebra/`
  - Core additive and multiplicative structures, identities, and composite algebraic objects (`Ring`, `Field`, etc.).
- `Modules/`
  - Left/right/bi-module actions, linear combinations, and module-related conveniences.
- `Multiplicative/`
  - Multiplicative invertibility witnesses and unit operations (`Unit`, `MultiplicativeInvertible`).
- `Collections/`
  - Collection-level additive/product operations (`sum`, `sumResult`, `product`, `productResult`).
- `Sign/`
  - Sign decomposition (`Signum`, `Signed`, absolute-value decomposition) and sign-related conveniences.
- `Utilities/`
  - Utility value types (`NonEmpty`, `NonZero`). `NonZero` is a zero-exclusion helper, not an invertibility witness.
- `Errors/`
  - Typed algebra errors and umbrella mapping.
- `Bridges/`
  - Bridges from standard-library numeric types into the algebra model.

## Naming convention

- `*Structures.swift` = protocol hierarchies and laws.
- `*Operations.swift` = consumer-facing operations over collections.
- `*Convenience.swift` = non-core ergonomics derived from core protocols.
