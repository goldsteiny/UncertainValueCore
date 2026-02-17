//
//  NonEmpty.swift
//  UncertainValueCoreAlgebra
//
//  Type-safe wrapper for non-empty collections.
//

public struct NonEmpty<Element: Sendable>: Sendable {
    public let head: Element
    public let tail: [Element]

    public init(_ head: Element, _ tail: [Element] = []) {
        self.head = head
        self.tail = tail
    }

    public init?(_ elements: [Element]) {
        guard let first = elements.first else { return nil }
        self.head = first
        self.tail = Array(elements.dropFirst())
    }

    public var array: [Element] {
        var values = [Element]()
        values.reserveCapacity(count)
        values.append(head)
        values.append(contentsOf: tail)
        return values
    }

    public var count: Int { 1 + tail.count }

    @inlinable
    public func map<Output: Sendable>(_ transform: (Element) -> Output) -> NonEmpty<Output> {
        NonEmpty<Output>(transform(head), tail.map(transform))
    }

    @inlinable
    public func reduce<Output>(_ nextPartialResult: (Output, Element) -> Output, initialTransform: (Element) -> Output) -> Output {
        tail.reduce(initialTransform(head), nextPartialResult)
    }
}

/// Backward-compatible alias.
public typealias NonEmptyArray<Element: Sendable> = NonEmpty<Element>

extension NonEmpty: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public subscript(position: Int) -> Element {
        if position == 0 {
            return head
        }
        return tail[position - 1]
    }
}

extension NonEmpty: Equatable where Element: Equatable {}
extension NonEmpty: Hashable where Element: Hashable {}
