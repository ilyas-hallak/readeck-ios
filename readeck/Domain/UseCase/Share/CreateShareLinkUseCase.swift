import Foundation

protocol PCreateShareLinkUseCase {
    func execute(bookmarkId: String) async throws -> URL
}

final class CreateShareLinkUseCase: PCreateShareLinkUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(bookmarkId: String) async throws -> URL {
        try await repository.createShareLink(id: bookmarkId)
    }
}
