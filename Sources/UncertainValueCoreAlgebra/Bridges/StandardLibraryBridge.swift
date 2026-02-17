//
//  StandardLibraryBridge.swift
//  UncertainValueCoreAlgebra
//
//  Aggressive bridges from Swift standard numeric types
//  into the algebra protocol tower.
//

/// Bridge signed integer scalars to the core algebra hierarchy.
public protocol SignedIntegerAlgebra:
    BinaryInteger,
    AdditiveAbelianGroup,
    MultiplicativeCommutativeMonoid,
    CommutativeRing,
    Signed,
    AbsoluteValueDecomposable,
    Sendable {}

public extension SignedIntegerAlgebra {
    @inlinable
    static var one: Self { 1 }

    @inlinable
    var signum: Signum {
        if isZero { return .zero }
        return self < 0 ? .negative : .positive
    }

    @inlinable
    var flippedSign: Self { -self }

    @inlinable
    var absolute: Self { self < 0 ? -self : self }
}

/// Bridge binary floating-point scalars to the core algebra hierarchy.
public protocol FloatingPointFieldAlgebra:
    BinaryFloatingPoint,
    AdditiveAbelianGroup,
    MultiplicativeCommutativeMonoidWithPartialReciprocal,
    Field,
    Signed,
    AbsoluteValueDecomposable,
    Sendable {}

public extension FloatingPointFieldAlgebra {
    @inlinable
    static var one: Self { 1 }

    @inlinable
    func reciprocal() -> Result<Self, ReciprocalOfZeroError> {
        guard !isZero else { return .failure(ReciprocalOfZeroError()) }
        return .success(1 / self)
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

extension Int: SignedIntegerAlgebra {}
extension Int8: SignedIntegerAlgebra {}
extension Int16: SignedIntegerAlgebra {}
extension Int32: SignedIntegerAlgebra {}
extension Int64: SignedIntegerAlgebra {}

extension Float: FloatingPointFieldAlgebra {}
extension Double: FloatingPointFieldAlgebra {}

#if swift(>=5.3)
extension Float16: FloatingPointFieldAlgebra {}
#endif
