//
//  GetCachedArticleUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

import Foundation

protocol PGetCachedArticleUseCase {
    func execute(id: String) -> String?
}

class GetCachedArticleUseCase: PGetCachedArticleUseCase {
    private let offlineCacheRepository: POfflineCacheRepository

    init(offlineCacheRepository: POfflineCacheRepository) {
        self.offlineCacheRepository = offlineCacheRepository
    }

    func execute(id: String) -> String? {
        return offlineCacheRepository.getCachedArticle(id: id)
    }
}
