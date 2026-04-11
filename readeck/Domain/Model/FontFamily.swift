//
//  FontFamily.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//

enum FontFamily: String, CaseIterable {
    // Apple System Fonts
    case system           // SF Pro
    case newYork         // New York
    case avenirNext   // Avenir Next
    case monospace     // SF Mono

    // Google Serif Fonts
    case literata
    case merriweather
    case sourceSerif

    // Google Sans Serif Fonts
    case lato
    case montserrat
    case sourceSans

    // Legacy (for backwards compatibility)
    case serif
    case sansSerif

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

    /// Returns the font file names (without extension) for this font family
    /// These correspond to the files listed in Info.plist under UIAppFonts
    // swiftlint:disable:next discouraged_optional_collection
    var fontFileNames: [(fileName: String, weight: String)]? {
        switch self {
        case .literata:
            return [
                ("Literata-Regular", "normal"),
                ("Literata-Bold", "bold")
            ]
        case .merriweather:
            return [
                ("Merriweather-Regular", "normal"),
                ("Merriweather-Bold", "bold")
            ]
        case .sourceSerif:
            return [
                ("SourceSerif4-Regular", "normal"),
                ("SourceSerif4-Bold", "bold")
            ]
        case .lato:
            return [
                ("Lato-Regular", "normal"),
                ("Lato-Bold", "bold")
            ]
        case .montserrat:
            return [
                ("Montserrat-Regular", "normal"),
                ("Montserrat-Bold", "bold")
            ]
        case .sourceSans:
            return [
                ("SourceSans3-Regular", "normal"),
                ("SourceSans3-Bold", "bold")
            ]
        // System fonts don't need to be loaded via @font-face
        case .system, .newYork, .avenirNext, .monospace, .serif, .sansSerif:
            return nil
        }
    }

    /// Returns the CSS font-family name used in @font-face declarations
    var cssFontFamily: String? {
        switch self {
        case .literata: return "Literata"
        case .merriweather: return "Merriweather"
        case .sourceSerif: return "Source Serif 4"
        case .lato: return "Lato"
        case .montserrat: return "Montserrat"
        case .sourceSans: return "Source Sans 3"
        // System fonts don't need CSS font-family names
        case .system, .newYork, .avenirNext, .monospace, .serif, .sansSerif:
            return nil
        }
    }
}

enum FontCategory {
    case serif
    case sansSerif
    case monospace
}
