import Foundation

enum CreateBookmarkError: Error, LocalizedError {
    case invalidURL
    case duplicateBookmark
    case networkError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die eingegebene URL ist ungültig"
        case .duplicateBookmark:
            return "Dieser Bookmark existiert bereits"
        case .networkError:
            return "Netzwerkfehler beim Erstellen des Bookmarks"
        case .serverError(let message):
            return message
        }
    }
} 