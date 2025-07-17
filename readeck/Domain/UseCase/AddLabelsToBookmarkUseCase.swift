import Foundation

protocol PAddLabelsToBookmarkUseCase {
    func execute(bookmarkId: String, labels: [String]) async throws
    func execute(bookmarkId: String, label: String) async throws
}

class AddLabelsToBookmarkUseCase: PAddLabelsToBookmarkUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(bookmarkId: String, labels: [String]) async throws {
        // Validierung der Labels
        guard !labels.isEmpty else {
            throw BookmarkUpdateError.emptyLabels
        }
        
        // Entferne leere Labels und Duplikate
        let cleanLabels = Array(Set(labels.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
        
        guard !cleanLabels.isEmpty else {
            throw BookmarkUpdateError.emptyLabels
        }
        
        let request = BookmarkUpdateRequest.addLabels(cleanLabels)
        try await repository.updateBookmark(id: bookmarkId, updateRequest: request)
    }
    
    // Convenience method für einzelne Labels
    func execute(bookmarkId: String, label: String) async throws {
        try await execute(bookmarkId: bookmarkId, labels: [label])
    }
}

// Custom error für Label-Operationen
enum BookmarkUpdateError: LocalizedError {
    case emptyLabels
    
    var errorDescription: String? {
        switch self {
        case .emptyLabels:
            return "Labels können nicht leer sein"
        }
    }
} 