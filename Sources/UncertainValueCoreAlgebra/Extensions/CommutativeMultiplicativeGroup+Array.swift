//
//  CommutativeMultiplicativeGroup+Array.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for multiplicative groups.
//

public extension Array where Element: ProductableMonoid {
    @inlinable
    func product() -> Result<Element, AlgebraError.EmptyCollection> {
        guard let nonEmpty = NonEmptyArray(self) else { return .failure(AlgebraError.EmptyCollection()) }
        return .success(Element.product(nonEmpty))
    }
}

public extension NonEmptyArray where Element: ProductableMonoid {
    @inlinable
    func product() -> Element {
        Element.product(self)
    }
}
