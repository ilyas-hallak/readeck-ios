import Foundation

class UpdateBookmarkUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(bookmarkId: String, updateRequest: BookmarkUpdateRequest) async throws {
        try await repository.updateBookmark(id: bookmarkId, updateRequest: updateRequest)
    }
    
    // Convenience methods für häufige Aktionen
    func toggleArchive(bookmarkId: String, isArchived: Bool) async throws {
        let request = BookmarkUpdateRequest.archive(isArchived)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func toggleFavorite(bookmarkId: String, isMarked: Bool) async throws {
        let request = BookmarkUpdateRequest.favorite(isMarked)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func markAsDeleted(bookmarkId: String) async throws {
        let request = BookmarkUpdateRequest.delete(true)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func updateReadProgress(bookmarkId: String, progress: Int, anchor: String? = nil) async throws {
        let request = BookmarkUpdateRequest.updateProgress(progress, anchor: anchor)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func updateTitle(bookmarkId: String, title: String) async throws {
        let request = BookmarkUpdateRequest.updateTitle(title)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func updateLabels(bookmarkId: String, labels: [String]) async throws {
        let request = BookmarkUpdateRequest.updateLabels(labels)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func addLabels(bookmarkId: String, labels: [String]) async throws {
        let request = BookmarkUpdateRequest.addLabels(labels)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
    
    func removeLabels(bookmarkId: String, labels: [String]) async throws {
        let request = BookmarkUpdateRequest.removeLabels(labels)
        try await execute(bookmarkId: bookmarkId, updateRequest: request)
    }
}