//
//  OfflineCacheRepository.swift
//  readeck
//
//  Created by Claude on 17.11.25.
//

import Foundation
import CoreData
import Kingfisher

class OfflineCacheRepository: POfflineCacheRepository {

    // MARK: - Dependencies

    private let coreDataManager = CoreDataManager.shared
    private let logger = Logger.sync

    // MARK: - Cache Operations

    func cacheBookmarkWithMetadata(bookmark: Bookmark, html: String, saveImages: Bool) async throws {
        if hasCachedArticle(id: bookmark.id) {
            logger.debug("Bookmark \(bookmark.id) is already cached, skipping")
            return
        }

        try await saveBookmarkToCache(bookmark: bookmark, html: html, saveImages: saveImages)

        if saveImages {
            await prefetchImagesForBookmark(id: bookmark.id)
        }
    }

    func getCachedArticle(id: String) -> String? {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND htmlContent != nil", id)
        fetchRequest.fetchLimit = 1

        do {
            let results = try coreDataManager.context.fetch(fetchRequest)
            if let entity = results.first {
                // Update last access date
                entity.lastAccessDate = Date()
                coreDataManager.save()
                logger.debug("Retrieved cached article for bookmark \(id)")
                return entity.htmlContent
            }
        } catch {
            logger.error("Error fetching cached article: \(error.localizedDescription)")
        }

        return nil
    }

    func hasCachedArticle(id: String) -> Bool {
        return getCachedArticle(id: id) != nil
    }

    func getCachedBookmarks() async throws -> [Bookmark] {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: false)]

        let context = coreDataManager.context
        return try await context.perform {
            let entities = try context.fetch(fetchRequest)
            self.logger.debug("Found \(entities.count) cached bookmarks")

            // Convert entities to Bookmark domain objects using mapper
            return entities.compactMap { $0.toDomain() }
        }
    }

    // MARK: - Cache Statistics

    func getCachedArticlesCount() -> Int {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")

        do {
            let count = try coreDataManager.context.count(for: fetchRequest)
            return count
        } catch {
            logger.error("Error counting cached articles: \(error.localizedDescription)")
            return 0
        }
    }

    func getCacheSize() -> String {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")

        do {
            let entities = try coreDataManager.context.fetch(fetchRequest)
            let totalBytes = entities.reduce(0) { $0 + $1.cacheSize }
            return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        } catch {
            logger.error("Error calculating cache size: \(error.localizedDescription)")
            return "0 KB"
        }
    }

    // MARK: - Cache Management

    func clearCache() async throws {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")

        let context = coreDataManager.context
        try await context.perform { [weak self] in
            guard let self = self else { return }

            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                entity.htmlContent = nil
                entity.cachedDate = nil
                entity.lastAccessDate = nil
                entity.imageURLs = nil
                entity.cacheSize = 0
            }

            try context.save()
            self.logger.info("Cleared cache for \(entities.count) articles")
        }

        // Optional: Also clear Kingfisher cache
        // KingfisherManager.shared.cache.clearDiskCache()
        // KingfisherManager.shared.cache.clearMemoryCache()
    }

    func cleanupOldestCachedArticles(keepCount: Int) async throws {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: true)]

        let context = coreDataManager.context
        try await context.perform { [weak self] in
            guard let self = self else { return }

            let allEntities = try context.fetch(fetchRequest)

            // Delete oldest articles if we exceed keepCount
            if allEntities.count > keepCount {
                let entitiesToDelete = allEntities.prefix(allEntities.count - keepCount)
                for entity in entitiesToDelete {
                    entity.htmlContent = nil
                    entity.cachedDate = nil
                    entity.lastAccessDate = nil
                    entity.imageURLs = nil
                    entity.cacheSize = 0
                }

                try context.save()
                self.logger.info("Cleaned up \(entitiesToDelete.count) oldest cached articles (keeping \(keepCount))")
            }
        }
    }

    // MARK: - Private Helper Methods

    private func saveBookmarkToCache(bookmark: Bookmark, html: String, saveImages: Bool) async throws {
        let context = coreDataManager.context

        try await context.perform { [weak self] in
            guard let self = self else { return }

            let entity = try self.findOrCreateEntity(for: bookmark.id, in: context)
            bookmark.updateEntity(entity)
            self.updateEntityWithCacheData(entity: entity, html: html, saveImages: saveImages)

            try context.save()
            self.logger.info("Cached bookmark \(bookmark.id) with HTML (\(html.utf8.count) bytes)")
        }
    }

    private func findOrCreateEntity(for bookmarkId: String, in context: NSManagedObjectContext) throws -> BookmarkEntity {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", bookmarkId)
        fetchRequest.fetchLimit = 1

        let existingEntities = try context.fetch(fetchRequest)
        return existingEntities.first ?? BookmarkEntity(context: context)
    }

    private func updateEntityWithCacheData(entity: BookmarkEntity, html: String, saveImages: Bool) {
        entity.htmlContent = html
        entity.cachedDate = Date()
        entity.lastAccessDate = Date()
        entity.cacheSize = Int64(html.utf8.count)

        if saveImages {
            let imageURLs = extractImageURLsFromHTML(html: html)
            if !imageURLs.isEmpty {
                entity.imageURLs = imageURLs.joined(separator: ",")
                logger.debug("Found \(imageURLs.count) images for bookmark \(entity.id ?? "unknown")")
            }
        }
    }

    private func prefetchImagesForBookmark(id: String) async {
        guard let entity = try? await getCachedEntity(id: id),
              let imageURLsString = entity.imageURLs else {
            return
        }

        let imageURLs = imageURLsString
            .split(separator: ",")
            .compactMap { URL(string: String($0)) }

        if !imageURLs.isEmpty {
            await prefetchImagesWithKingfisher(imageURLs: imageURLs)
        }
    }

    private func extractImageURLsFromHTML(html: String) -> [String] {
        var imageURLs: [String] = []

        // Simple regex pattern for img tags
        let pattern = #"<img[^>]+src=\"([^\"]+)\""#

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

            for result in results {
                if result.numberOfRanges >= 2 {
                    let urlRange = result.range(at: 1)
                    if let url = nsString.substring(with: urlRange) as String? {
                        // Only include absolute URLs (http/https)
                        if url.hasPrefix("http") {
                            imageURLs.append(url)
                        }
                    }
                }
            }
        }

        logger.debug("Extracted \(imageURLs.count) image URLs from HTML")
        return imageURLs
    }

    private func prefetchImagesWithKingfisher(imageURLs: [URL]) async {
        guard !imageURLs.isEmpty else { return }

        logger.info("Starting Kingfisher prefetch for \(imageURLs.count) images")

        // Use Kingfisher's prefetcher with low priority
        let prefetcher = ImagePrefetcher(urls: imageURLs) { [weak self] skippedResources, failedResources, completedResources in
            self?.logger.info("Prefetch completed: \(completedResources.count)/\(imageURLs.count) images cached")
            if !failedResources.isEmpty {
                self?.logger.warning("Failed to cache \(failedResources.count) images")
            }
        }

        // Optional: Set download priority to low for background downloads
        // prefetcher.options = [.downloadPriority(.low)]

        prefetcher.start()
    }

    private func getCachedEntity(id: String) async throws -> BookmarkEntity? {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.fetchLimit = 1

        let context = coreDataManager.context
        return try await context.perform {
            let results = try context.fetch(fetchRequest)
            return results.first
        }
    }
}
