//
//  NonEmptyArray.swift
//  UncertainValueCoreAlgebra
//
//  Type-safe wrapper guaranteeing a non-empty collection.
//

public struct NonEmptyArray<Element: Sendable>: Sendable {
    public let head: Element
    public let tail: [Element]

    public init(_ head: Element, _ tail: [Element] = []) {
        self.head = head
        self.tail = tail
    }

    public init?(_ array: [Element]) {
        guard let first = array.first else { return nil }
        self.head = first
        self.tail = Array(array.dropFirst())
    }

    public var array: [Element] { [head] + tail }
    public var count: Int { 1 + tail.count }

    public func map<T: Sendable>(_ transform: (Element) -> T) -> NonEmptyArray<T> {
        NonEmptyArray<T>(transform(head), tail.map(transform))
    }

    public func reduce<T>(_ nextPartialResult: (T, Element) -> T, initialTransform: (Element) -> T) -> T {
        tail.reduce(initialTransform(head), nextPartialResult)
    }
}

// MARK: - Collection

extension NonEmptyArray: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public subscript(position: Int) -> Element {
        position == 0 ? head : tail[position - 1]
    }
}

// MARK: - Equatable, Hashable

extension NonEmptyArray: Equatable where Element: Equatable {}
extension NonEmptyArray: Hashable where Element: Hashable {}
