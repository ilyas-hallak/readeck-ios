//
//  Constants.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.07.25.
//
//  SPDX-License-Identifier: MIT
//
//  This file is part of the readeck project and is licensed under the MIT License.
//

import Foundation
import SwiftUI

struct Constants {
    // Annotation colors
    static let annotationColors: [AnnotationColor] = [.yellow, .green, .blue, .red]
}

enum AnnotationColor: String, CaseIterable, Codable {
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case red = "red"

    // Base hex color for buttons and overlays
    var hexColor: String {
        switch self {
        case .yellow: return "#D4A843"
        case .green: return "#6FB546"
        case .blue: return "#4A9BB8"
        case .red: return "#C84848"
        }
    }

    // RGB values for SwiftUI Color
    private var rgb: (red: Double, green: Double, blue: Double) {
        switch self {
        case .yellow: return (212, 168, 67)
        case .green: return (111, 181, 70)
        case .blue: return (74, 155, 184)
        case .red: return (200, 72, 72)
        }
    }

    func swiftUIColor(isDark: Bool) -> Color {
        let (r, g, b) = rgb
        return Color(red: r/255, green: g/255, blue: b/255)
    }

    // CSS rgba string for JavaScript (for highlighting)
    func cssColor(isDark: Bool) -> String {
        let (r, g, b) = rgb
        return "rgba(\(Int(r)), \(Int(g)), \(Int(b)), 0.3)"
    }

    // CSS rgba string with custom opacity
    func cssColorWithOpacity(_ opacity: Double) -> String {
        let (r, g, b) = rgb
        return "rgba(\(Int(r)), \(Int(g)), \(Int(b)), \(opacity))"
    }
}
