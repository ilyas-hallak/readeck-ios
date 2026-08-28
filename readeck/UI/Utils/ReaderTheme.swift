//
//  ReaderTheme.swift
//  readeck
//

import SwiftUI

/// The colors the reader actually paints with, after `ReaderColorTheme.system` has
/// been resolved against the current appearance and `.custom` against the user's
/// stored hex values.
///
/// Both the SwiftUI chrome (view background, navigation bar, title, meta rows) and
/// the CSS injected into the web view read from here, so the native frame and the
/// article content cannot drift apart.
struct ReaderTheme: Equatable {
    let backgroundHex: String
    let textHex: String
    let headingHex: String

    var backgroundColor: Color { Color(hex: backgroundHex) }
    var textColor: Color { Color(hex: textHex) }
    var secondaryTextColor: Color { textColor.opacity(0.6) }

    /// Slightly tinted background for cards that have to lift off the page without
    /// breaking out of the theme.
    var surfaceColor: Color {
        Color(hex: Self.blend(backgroundHex, toward: textHex, amount: 0.08))
    }

    /// True when the resolved background needs light foreground content. Derived from
    /// the background's brightness instead of the theme case, so it also covers
    /// `.system` and user-picked `.custom` colors.
    var isDark: Bool { Self.brightness(ofHex: backgroundHex) < 0.5 }

    /// Color scheme the reader adopts so system-tinted controls and the navigation
    /// bar stay legible on the resolved background.
    var colorScheme: ColorScheme { isDark ? .dark : .light }

    /// Resolves the effective reader colors.
    /// - Parameter isDarkMode: The appearance the `.system` theme falls back to.
    static func resolve(settings: Settings?, isDarkMode: Bool) -> Self {
        let theme = settings?.readerColorTheme ?? .system
        // Pure black instead of the elevated system gray: the reader should read as
        // one sheet of paper, and the OLED app theme expects a black reader too.
        let systemBackground = isDarkMode ? "#000000" : "#ffffff"
        let systemText = isDarkMode ? "#ffffff" : "#1a1a1a"

        switch theme {
        case .system:
            return Self(
                backgroundHex: systemBackground,
                textHex: systemText,
                headingHex: isDarkMode ? "#ffffff" : "#000000"
            )
        case .custom:
            let text = settings?.customTextColor ?? systemText
            return Self(
                backgroundHex: settings?.customBackgroundColor ?? systemBackground,
                textHex: text,
                headingHex: text
            )
        default:
            let text = theme.textHex ?? systemText
            return Self(
                backgroundHex: theme.backgroundHex ?? systemBackground,
                textHex: text,
                headingHex: text
            )
        }
    }

    // MARK: - Hex helpers

    private static func components(ofHex hex: String) -> (r: Double, g: Double, b: Double) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&value)

        return (
            Double((value & 0xFF0000) >> 16) / 255.0,
            Double((value & 0x00FF00) >> 8) / 255.0,
            Double(value & 0x0000FF) / 255.0
        )
    }

    /// Perceived brightness in the 0...1 range.
    private static func brightness(ofHex hex: String) -> Double {
        let rgb = components(ofHex: hex)
        return 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b
    }

    private static func blend(_ hex: String, toward other: String, amount: Double) -> String {
        let base = components(ofHex: hex)
        let target = components(ofHex: other)
        let mix = { (lhs: Double, rhs: Double) in
            Int((lhs + (rhs - lhs) * amount) * 255.0)
        }

        return String(format: "#%02X%02X%02X", mix(base.r, target.r), mix(base.g, target.g), mix(base.b, target.b))
    }
}
