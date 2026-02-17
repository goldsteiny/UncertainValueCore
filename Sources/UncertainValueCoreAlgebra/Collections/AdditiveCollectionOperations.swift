//
//  AdditiveCollectionOperations.swift
//  UncertainValueCoreAlgebra
//
//  Collection conveniences for additive structures.
//

public extension Array where Element: AdditiveMonoid {
    @inlinable
    func sum() -> Element {
        guard let values = NonEmpty(self) else { return .zero }
        return Element.sum(values)
    }
}

public extension Array where Element: AdditiveSemigroup {
    @inlinable
    func sumResult() -> Result<Element, EmptyCollectionError> {
        guard let values = NonEmpty(self) else { return .failure(EmptyCollectionError()) }
        return .success(Element.sum(values))
    }
}

public extension NonEmpty where Element: AdditiveSemigroup {
    @inlinable
    func sum() -> Element {
        Element.sum(self)
    }
}
