//
//  CommutativeAdditiveGroup+Array.swift
//  UncertainValueCoreAlgebra
//
//  Array conveniences for additive groups.
//

public extension Array where Element: SummableGroup {
    @inlinable
    func sum() -> Result<Element, EmptyCollectionError> {
        guard let nonEmpty = NonEmptyArray(self) else { return .failure(EmptyCollectionError()) }
        return .success(Element.sum(nonEmpty))
    }
}

public extension NonEmptyArray where Element: SummableGroup {
    @inlinable
    func sum() -> Element {
        Element.sum(self)
    }
}

public extension NonEmptyArray where Element: CommutativeAdditiveGroup & Scalable {
    func mean() -> Element {
        let recipN = NonZero<Element.Scalar>(1 / Element.Scalar(count))!
        return Element.sum(self).scaled(by: recipN)
    }
}
