import Foundation

class CreateBookmarkUseCase {
    private let repository: PBookmarksRepository
    
    init(repository: PBookmarksRepository) {
        self.repository = repository
    }
    
    func execute(createRequest: CreateBookmarkRequest) async throws -> String {
        // URL-Validierung
        guard URL(string: createRequest.url) != nil else {
            throw CreateBookmarkError.invalidURL
        }
        
        return try await repository.createBookmark(createRequest: createRequest)
    }
    
    // Convenience methods für häufige Use Cases
    func createFromURL(_ url: String) async throws -> String {
        let request = CreateBookmarkRequest.fromURL(url)
        return try await execute(createRequest: request)
    }
    
    func createFromURLWithTitle(_ url: String, title: String) async throws -> String {
        let request = CreateBookmarkRequest.fromURLWithTitle(url, title: title)
        return try await execute(createRequest: request)
    }
    
    func createFromURLWithLabels(_ url: String, labels: [String]) async throws -> String {
        let request = CreateBookmarkRequest.fromURLWithLabels(url, labels: labels)
        return try await execute(createRequest: request)
    }
    
    func createFromClipboard() async throws -> String? {
        return nil
        // URL aus Zwischenablage holen (falls verfügbar)
        /*#if canImport(UIKit)
        import UIKit
        guard let clipboardString = UIPasteboard.general.string,
              URL(string: clipboardString) != nil else {
            return nil
        }
        
        let request = CreateBookmarkRequest.fromURL(clipboardString)
        return try await execute(createRequest: request)
        #else
        return nil
        #endif*/
    }
}
