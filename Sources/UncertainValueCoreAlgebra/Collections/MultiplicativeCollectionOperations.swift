//
//  MultiplicativeCollectionOperations.swift
//  UncertainValueCoreAlgebra
//
//  Collection conveniences for multiplicative structures.
//

public extension Array where Element: MultiplicativeMonoid {
    @inlinable
    func product() -> Element {
        guard let values = NonEmpty(self) else { return .one }
        return Element.product(values)
    }
}

public extension Array where Element: MultiplicativeSemigroup {
    @inlinable
    func productResult() -> Result<Element, EmptyCollectionError> {
        guard let values = NonEmpty(self) else { return .failure(EmptyCollectionError()) }
        return .success(Element.product(values))
    }
}

public extension NonEmpty where Element: MultiplicativeSemigroup {
    @inlinable
    func product() -> Element {
        Element.product(self)
    }
}
