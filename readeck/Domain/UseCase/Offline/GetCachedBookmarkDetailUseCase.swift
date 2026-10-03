import Foundation

protocol PGetCachedBookmarkDetailUseCase {
    func execute(id: String) -> BookmarkDetail?
}

final class GetCachedBookmarkDetailUseCase: PGetCachedBookmarkDetailUseCase {
    private let offlineCacheRepository: POfflineCacheRepository

    init(offlineCacheRepository: POfflineCacheRepository) {
        self.offlineCacheRepository = offlineCacheRepository
    }

    func execute(id: String) -> BookmarkDetail? {
        offlineCacheRepository.getCachedBookmarkDetail(id: id)
    }
}
