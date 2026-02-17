//
//  Algebra.swift
//  UncertainValueCoreAlgebra
//
//  Combined algebraic structures.
//

public protocol AlgebraicVector: CommutativeAdditiveGroup, Scalable {}

public protocol AlgebraWithZero: AdditiveGroup, MultiplicativeMonoidWithInverse, Scalable {}

public protocol AlgebraWithoutZero: AdditiveGroup, MultiplicativeGroup, Scalable {}

public protocol CommutativeAlgebraWithZero: CommutativeAdditiveGroup, CommutativeMultiplicativeMonoidWithInverse, Scalable {}

public protocol CommutativeAlgebraWithoutZero: CommutativeAdditiveGroup, CommutativeMultiplicativeGroup, Scalable {}
