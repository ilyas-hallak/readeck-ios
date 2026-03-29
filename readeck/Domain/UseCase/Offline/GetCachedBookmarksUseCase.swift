//
//  GetCachedBookmarksUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

import Foundation

protocol PGetCachedBookmarksUseCase {
    func execute() async throws -> [Bookmark]
}

final class GetCachedBookmarksUseCase: PGetCachedBookmarksUseCase {
    private let offlineCacheRepository: POfflineCacheRepository

    init(offlineCacheRepository: POfflineCacheRepository) {
        self.offlineCacheRepository = offlineCacheRepository
    }

    func execute() async throws -> [Bookmark] {
        try await offlineCacheRepository.getCachedBookmarks()
    }
}
