//
//  FontFamily.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//

enum FontFamily: String, CaseIterable {
    // Apple System Fonts
    case system = "system"           // SF Pro
    case newYork = "newYork"         // New York
    case avenirNext = "avenirNext"   // Avenir Next
    case monospace = "monospace"     // SF Mono

    // Google Serif Fonts
    case literata = "literata"
    case merriweather = "merriweather"
    case sourceSerif = "sourceSerif"

    // Google Sans Serif Fonts
    case lato = "lato"
    case montserrat = "montserrat"
    case sourceSans = "sourceSans"

    // Legacy (for backwards compatibility)
    case serif = "serif"
    case sansSerif = "sansSerif"

    var displayName: String {
        switch self {
        // Apple
        case .system: return "SF Pro"
        case .newYork: return "New York"
        case .avenirNext: return "Avenir Next"
        case .monospace: return "SF Mono"

        // Serif
        case .literata: return "Literata *"
        case .merriweather: return "Merriweather *"
        case .sourceSerif: return "Source Serif *"

        // Sans Serif
        case .lato: return "Lato"
        case .montserrat: return "Montserrat"
        case .sourceSans: return "Source Sans *"

        // Legacy
        case .serif: return "Serif (Legacy)"
        case .sansSerif: return "Sans Serif (Legacy)"
        }
    }

    var category: FontCategory {
        switch self {
        case .system, .avenirNext, .lato, .montserrat, .sourceSans, .sansSerif:
            return .sansSerif
        case .newYork, .literata, .merriweather, .sourceSerif, .serif:
            return .serif
        case .monospace:
            return .monospace
        }
    }

    var isReadeckWebMatch: Bool {
        switch self {
        case .literata, .merriweather, .sourceSerif, .sourceSans:
            return true
        default:
            return false
        }
    }
}

enum FontCategory {
    case serif
    case sansSerif
    case monospace
}