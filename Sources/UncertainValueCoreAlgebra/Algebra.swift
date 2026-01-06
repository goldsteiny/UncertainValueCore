//
//  Algebra.swift
//  UncertainValueCoreAlgebra
//
//  Combined algebraic structures.
//

import Foundation

/// Additive commutative group with scalar scaling.
public protocol AlgebraicVector: CommutativeAdditiveGroup, Scalable {}

/// Algebra with zero (additive group + multiplicative group with zero + scaling).
public protocol AlgebraWithZero: AdditiveGroup, MultiplicativeGroupWithZero, Scalable {}

/// Algebra without zero (additive group + multiplicative group without zero + scaling).
public protocol AlgebraWithoutZero: AdditiveGroup, MultiplicativeGroupWithoutZero, Scalable {}

/// Commutative algebra with zero.
public protocol CommutativeAlgebraWithZero: CommutativeAdditiveGroup, CommutativeMultiplicativeGroupWithZero, Scalable {}

/// Commutative algebra without zero.
public protocol CommutativeAlgebraWithoutZero: CommutativeAdditiveGroup, CommutativeMultiplicativeGroupWithoutZero, Scalable {}
