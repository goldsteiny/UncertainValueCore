//
//  StandardLibraryBridge.swift
//  UncertainValueCoreAlgebra
//
//  Bridges from Swift standard floating-point types
//  into the algebra protocol tower.
//

/// Bridge binary floating-point scalars to the core algebra hierarchy.
public protocol FloatingPointFieldAlgebra:
    BinaryFloatingPoint,
    AdditiveAbelianGroup,
    MultiplicativeCommutativeMonoidWithUnits,
    Field,
    Signed,
    AbsoluteValueDecomposable,
    Sendable {}

public extension FloatingPointFieldAlgebra {
    @inlinable
    static var one: Self { 1 }

    @inlinable
    var unit: Unit<Self>? {
        guard !isZero else { return nil }
        return Unit(unchecked: self, reciprocal: 1 / self)
    }

    @inlinable
    var signum: Signum {
        if isZero { return .zero }
        return sign == .minus ? .negative : .positive
    }

    @inlinable
    var flippedSign: Self { -self }

    @inlinable
    var absolute: Self { Swift.abs(self) }
}

extension Float: FloatingPointFieldAlgebra {}
extension Double: FloatingPointFieldAlgebra {}

#if swift(>=5.3)
extension Float16: FloatingPointFieldAlgebra {}
#endif
