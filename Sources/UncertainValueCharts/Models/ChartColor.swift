//
//  ChartColor.swift
//  BoundedValuesCharts
//
//  Shared chart color tokens.
//

import SwiftUI

public enum ChartColor: String, CaseIterable, Sendable {
    case blue
    case red
    case green
    case orange
    case purple
    case cyan

    public var swiftUIColor: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .cyan: return .cyan
        }
    }
}
