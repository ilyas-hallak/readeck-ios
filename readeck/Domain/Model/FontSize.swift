//
//  FontSize.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//

import Foundation

enum FontSize: String, CaseIterable {
    case small
    case medium
    case large
    case extraLarge

    var displayName: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        }
    }

    var size: Double {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
}
