import Foundation

protocol PShareByEmailUseCase {
    func execute(bookmarkId: String, email: String, format: EmailShareFormat) async throws
}

final class ShareByEmailUseCase: PShareByEmailUseCase {
    private let repository: PBookmarksRepository

    init(repository: PBookmarksRepository) {
        self.repository = repository
    }

    func execute(bookmarkId: String, email: String, format: EmailShareFormat) async throws {
        try await repository.shareByEmail(id: bookmarkId, email: email, format: format)
    }
}
