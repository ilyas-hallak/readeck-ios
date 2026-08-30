//
//  Theme.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.07.25.
//


import SwiftUI

enum Theme: String, CaseIterable {
    case system
    case light
    case dark
    case oled

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .oled: return "OLED"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .oled: return .dark
        }
    }

    /// True when the theme forces pure-black (#000000) surfaces instead of the
    /// system's elevated dark grays. Used to tint app chrome and scroll backgrounds.
    var isOLED: Bool { self == .oled }
}
