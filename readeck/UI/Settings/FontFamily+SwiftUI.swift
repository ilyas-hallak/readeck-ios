import SwiftUI

extension FontFamily {
    /// The SwiftUI font that matches what the reader renders for this family.
    func font(size: Double, bold: Bool = false) -> Font {
        let weight: Font.Weight = bold ? .semibold : .regular
        switch self {
        case .system:
            return .system(size: size, weight: weight)
        case .newYork:
            return .system(size: size, weight: weight, design: .serif)
        case .avenirNext:
            return .custom(bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular", size: size)
        case .monospace:
            return .system(size: size, weight: weight, design: .monospaced)
        case .literata:
            return .custom(bold ? "Literata-Bold" : "Literata-Regular", size: size)
        case .merriweather:
            return .custom(bold ? "Merriweather-Bold" : "Merriweather-Regular", size: size)
        case .sourceSerif:
            return .custom(bold ? "SourceSerif4-Bold" : "SourceSerif4-Regular", size: size)
        case .lato:
            return .custom(bold ? "Lato-Bold" : "Lato-Regular", size: size)
        case .montserrat:
            return .custom(bold ? "Montserrat-Bold" : "Montserrat-Regular", size: size)
        case .sourceSans:
            return .custom(bold ? "SourceSans3-Bold" : "SourceSans3-Regular", size: size)
        case .serif:
            return .custom("Times New Roman", size: size).weight(weight)
        case .sansSerif:
            return .custom("Helvetica Neue", size: size).weight(weight)
        }
    }
}
