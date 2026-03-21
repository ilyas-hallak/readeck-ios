//
//  ReaderColorTheme.swift
//  readeck
//

import SwiftUI

enum ReaderColorTheme: String, CaseIterable {
    case system = "system"
    case sepia = "sepia"
    case nightBlue = "nightBlue"
    case mint = "mint"
    case solarizedLight = "solarizedLight"
    case solarizedDark = "solarizedDark"
    case gray = "gray"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .system: return "System"
        case .sepia: return "Sepia"
        case .nightBlue: return "Night Blue"
        case .mint: return "Mint"
        case .solarizedLight: return "Solarized Light"
        case .solarizedDark: return "Solarized Dark"
        case .gray: return "Gray"
        case .custom: return "Custom"
        }
    }

    var backgroundColor: Color? {
        switch self {
        case .system: return nil
        case .sepia: return Color(hex: "F4ECD8")
        case .nightBlue: return Color(hex: "1B2838")
        case .mint: return Color(hex: "E8F5E9")
        case .solarizedLight: return Color(hex: "FDF6E3")
        case .solarizedDark: return Color(hex: "002B36")
        case .gray: return Color(hex: "2C2C2E")
        case .custom: return nil
        }
    }

    var textColor: Color? {
        switch self {
        case .system: return nil
        case .sepia: return Color(hex: "5B4636")
        case .nightBlue: return Color(hex: "C8D6E5")
        case .mint: return Color(hex: "2E4D3A")
        case .solarizedLight: return Color(hex: "657B83")
        case .solarizedDark: return Color(hex: "839496")
        case .gray: return Color(hex: "E5E5EA")
        case .custom: return nil
        }
    }

    var backgroundHex: String? {
        switch self {
        case .system: return nil
        case .sepia: return "#F4ECD8"
        case .nightBlue: return "#1B2838"
        case .mint: return "#E8F5E9"
        case .solarizedLight: return "#FDF6E3"
        case .solarizedDark: return "#002B36"
        case .gray: return "#2C2C2E"
        case .custom: return nil
        }
    }

    var textHex: String? {
        switch self {
        case .system: return nil
        case .sepia: return "#5B4636"
        case .nightBlue: return "#C8D6E5"
        case .mint: return "#2E4D3A"
        case .solarizedLight: return "#657B83"
        case .solarizedDark: return "#839496"
        case .gray: return "#E5E5EA"
        case .custom: return nil
        }
    }

    var isDark: Bool {
        switch self {
        case .nightBlue, .solarizedDark, .gray: return true
        default: return false
        }
    }
}

// MARK: - Color hex extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        let r = Int(max(0, min(1, components[0])) * 255)
        let g = Int(max(0, min(1, components.count > 1 ? components[1] : 0)) * 255)
        let b = Int(max(0, min(1, components.count > 2 ? components[2] : 0)) * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
