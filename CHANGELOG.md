# Changelog

## Unreleased
- Added MultiplicativeUncertainValue module (log-domain multiplicative uncertainty).
- Added UncertainValueStatistics module (arithmetic/geometric means and standard deviation helpers).
- Added UncertainValueCoreAlgebra package for algebra protocols; UncertainValue and MultiplicativeUncertainValue now conform to and build on these protocols.
- Breaking: renamed MeasurementMath to UncertainValueMath.
- Breaking: adjusted error-handling around `reciprocal`, `dividing`, and `raised` to use a more consistent mix of optionals vs throws.

## 1.0.0 - Initial public release
- Initial release of UncertainValueCore and related modules.
