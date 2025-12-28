# UncertainValueCore

A Swift library for arithmetic with measurement uncertainties. Propagates 1-sigma errors through calculations using configurable norm strategies (L1, L2, Lp), suitable for physics lab data analysis and scientific computing.

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/goldsteiny/UncertainValueCore.git", from: "1.0.0")
]
```

Then add the target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: ["UncertainValueCore"]
    // Or use "UncertainValueConvenience" for operator syntax
)
```

### Xcode

File > Add Package Dependencies... and enter the repository URL.

## Usage

### Core API (explicit norm strategy)

```swift
import UncertainValueCore

// Create values with uncertainty
let x = UncertainValue(10.0, absoluteError: 0.5)          // 10.0 +/- 0.5
let y = UncertainValue.withRelativeError(5.0, 0.04)       // 5.0 +/- 4%

// Arithmetic with explicit norm
let sum = x.adding(y, using: .l2)                         // L2 (quadrature)
let product = x.multiplying(y, using: .l1)                // L1 (linear sum)

// Single-operand operations (no norm needed)
let squared = x.raised(to: 2)                             // x^2
let inverse = x.reciprocal                                // 1/x

// Transcendental functions
let logX = MeasurementMath.log(x)                         // ln(x)
let expX = MeasurementMath.exp(x)                         // e^x

// Array operations
let values = [x, y]
let total = values.sum(using: .l2)
let prod = values.product(using: .l2)
```

### Convenience Operators (L2 only)

```swift
import UncertainValueCore
import UncertainValueConvenience

let x = UncertainValue(10.0, absoluteError: 0.5)
let y = UncertainValue(5.0, absoluteError: 0.3)

// Standard operators use L2 norm
let sum = x + y
let diff = x - y
let product = x * y
let quotient = x / y    // Returns Optional

// Mixed with constants
let scaled = x * 2.0
let shifted = x + 5.0
```

## Assumptions

- **Independent uncertainties**: Correlation is not modeled; handle covariance externally.
- **1-sigma propagation**: Uncertainties represent one standard deviation. The library propagates these using standard error formulas.
- **Valid range**: Designed for values in the range 1e-20 to 1e20. No special handling for overflow/underflow beyond this range.

## License

Apache-2.0. See [LICENSE](LICENSE) for details.
