//
//  POfflineCacheRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 17.11.25.
//

import Foundation

protocol POfflineCacheRepository {
    // Cache operations
    func cacheBookmarkWithMetadata(bookmark: Bookmark, html: String, saveImages: Bool) async throws
    func hasCachedArticle(id: String) -> Bool
    func getCachedArticle(id: String) -> String?
    func getCachedBookmarks() async throws -> [Bookmark]

    // Cache statistics
    func getCachedArticlesCount() -> Int
    func getCacheSize() -> String

    // Cache management
    func clearCache() async throws
    func cleanupOldestCachedArticles(keepCount: Int) async throws
}
