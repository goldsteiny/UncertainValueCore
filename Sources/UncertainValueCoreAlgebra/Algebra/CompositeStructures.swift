//
//  CompositeStructures.swift
//  UncertainValueCoreAlgebra
//
//  Composite algebraic structures.
//

public protocol Semiring: AdditiveMonoid, MultiplicativeMonoid {}
public protocol CommutativeSemiring: Semiring, MultiplicativeCommutativeMonoid {}

public protocol Ring: Semiring, AdditiveAbelianGroup {}
public protocol CommutativeRing: Ring, CommutativeSemiring {}

/// Also called a skew field in non-commutative settings.
public protocol DivisionRing: Ring, MultiplicativeMonoidWithUnits {}
public protocol Field: DivisionRing, CommutativeRing, MultiplicativeCommutativeMonoidWithUnits {}

public protocol LeftModuleOverRing: LeftModule where Scalar: Ring {}
public protocol RightModuleOverRing: RightModule where Scalar: Ring {}
public protocol BimoduleOverRing: Bimodule where Scalar: Ring {}

public protocol LeftVectorSpace: LeftModule, AdditiveAbelianGroup where Scalar: Field {}
public protocol RightVectorSpace: RightModule, AdditiveAbelianGroup where Scalar: Field {}
public protocol VectorSpace: Bimodule, AdditiveAbelianGroup where Scalar: Field {}
