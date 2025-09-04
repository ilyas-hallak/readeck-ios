import Foundation

enum CardLayoutStyle: String, CaseIterable, Codable {
    case compact = "compact"
    case magazine = "magazine"
    case natural = "natural"
    
    var displayName: String {
        switch self {
        case .compact:
            return "Compact"
        case .magazine:
            return "Magazine"
        case .natural:
            return "Natural"
        }
    }
    
    var description: String {
        switch self {
        case .compact:
            return "Small thumbnails with content focus"
        case .magazine:
            return "Fixed height headers for consistent layout"
        case .natural:
            return "Images in original aspect ratio"
        }
    }
}