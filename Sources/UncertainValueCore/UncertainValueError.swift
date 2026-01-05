//
//  UncertainValueError.swift
//  UncertainValueCore
//
//  Error types for invalid mathematical operations.
//

import Foundation

/// Errors thrown by UncertainValue operations.
public enum UncertainValueError: Error, Equatable {
    /// Attempted division or reciprocal of zero.
    case divisionByZero
}
