//
//  ValueErrorProviding.swift
//  UncertainValueSupport
//
//  Protocols for values with relative, absolute, or multiplicative errors.
//

import Foundation

public protocol ValueProviding: Sendable {
    associatedtype Scalar: BinaryFloatingPoint
    var value: Scalar { get }
}

public extension ValueProviding {
    @inlinable
    var absoluteValue: Scalar {
        abs(value)
    }
}

public protocol RelativeErrorProviding: ValueProviding {
    var relativeError: Scalar { get }
}

public extension RelativeErrorProviding {
    @inlinable
    var isErrorFree: Bool {
        relativeError == 0
    }

    @inlinable
    var absoluteErrorEstimate: Scalar {
        abs(value) * relativeError
    }

    @inlinable
    var multiplicativeErrorEstimate: Scalar {
        1 + relativeError
    }

    @inlinable
    var variance: Scalar {
        let error = absoluteErrorEstimate
        return error * error
    }
}

public protocol AbsoluteErrorProviding: RelativeErrorProviding {
    var absoluteError: Scalar { get }
}

public extension AbsoluteErrorProviding {
    @inlinable
    var absoluteErrorEstimate: Scalar {
        absoluteError
    }

    @inlinable
    var relativeError: Scalar {
        let denominator = absoluteValue
        guard denominator > 0 else { return absoluteError == 0 ? 0 : .infinity }
        return absoluteError / denominator
    }
}

public protocol MultiplicativeErrorProviding: ValueProviding {
    var multiplicativeError: Scalar { get }
}

public extension MultiplicativeErrorProviding {
    @inlinable
    var multiplicativeErrorEstimate: Scalar {
        multiplicativeError
    }

    @inlinable
    var relativeError: Scalar {
        multiplicativeError - 1
    }
}

public extension Array where Element: ValueProviding {
    @inlinable
    var values: [Element.Scalar] {
        map(\.value)
    }
}

public extension Array where Element: RelativeErrorProviding {
    @inlinable
    var relativeErrors: [Element.Scalar] {
        map(\.relativeError)
    }

    @inlinable
    var allErrorFree: Bool {
        allSatisfy(\.isErrorFree)
    }
}

public extension Array where Element: AbsoluteErrorProviding {
    @inlinable
    var absoluteErrors: [Element.Scalar] {
        map(\.absoluteError)
    }
}

public extension Array where Element: AbsoluteErrorProviding, Element.Scalar == Double {
    @inlinable
    func absoluteErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(absoluteErrors, using: strategy)
    }
}

public extension Array where Element: RelativeErrorProviding, Element.Scalar == Double {
    @inlinable
    func relativeErrorVectorLength(using strategy: NormStrategy) -> Double {
        norm(relativeErrors, using: strategy)
    }
}
