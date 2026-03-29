//
//  OfflineCacheRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 17.11.25.
//

import Foundation
import CoreData
import Kingfisher

final class OfflineCacheRepository: POfflineCacheRepository {
    // MARK: - Dependencies

    private let coreDataManager = CoreDataManager.shared
    private let logger = Logger.sync

    // MARK: - Cache Operations

    func cacheBookmarkWithMetadata(bookmark: Bookmark, html: String, saveImages: Bool) async throws {
        if hasCachedArticle(id: bookmark.id) {
            logger.debug("Bookmark \(bookmark.id) is already cached, skipping")
            return
        }

        // First prefetch images into Kingfisher cache
        if saveImages {
            var imageURLs = extractImageURLsFromHTML(html: html)

            // Add hero/thumbnail image if available and cache it with custom key
            if let heroImageUrl = bookmark.resources.image?.src {
                imageURLs.insert(heroImageUrl, at: 0)
                logger.debug("Added hero image: \(heroImageUrl)")

                // Cache hero image with custom key for offline access
                if let heroURL = URL(string: heroImageUrl) {
                    await cacheHeroImage(url: heroURL, bookmarkId: bookmark.id)
                }
            } else if let thumbnailUrl = bookmark.resources.thumbnail?.src {
                imageURLs.insert(thumbnailUrl, at: 0)
                logger.debug("Added thumbnail image: \(thumbnailUrl)")

                // Cache thumbnail with custom key
                if let thumbURL = URL(string: thumbnailUrl) {
                    await cacheHeroImage(url: thumbURL, bookmarkId: bookmark.id)
                }
            }

            let urls = imageURLs.compactMap { URL(string: $0) }
            await prefetchImagesWithKingfisher(imageURLs: urls)
        }

        // Then embed images as Base64 in HTML
        let processedHTML = saveImages ? await embedImagesAsBase64(html: html) : html

        // Save bookmark with embedded images
        try await saveBookmarkToCache(bookmark: bookmark, html: processedHTML, saveImages: saveImages)
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
        getCachedArticle(id: id) != nil
    }

    func getCachedBookmarks() async throws -> [Bookmark] {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: false)]

        let context = coreDataManager.context
        return try await context.perform {
            // First check total bookmarks
            let allRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            let totalCount = try? context.count(for: allRequest)
            self.logger.info("📊 Total bookmarks in Core Data: \(totalCount ?? 0)")

            let entities = try context.fetch(fetchRequest)
            self.logger.info("📊 getCachedBookmarks: Found \(entities.count) bookmarks with htmlContent != nil")

            if !entities.isEmpty {
                // Log details of first cached bookmark
                if let first = entities.first {
                    self.logger.info("   First cached: id=\(first.id ?? "nil"), title=\(first.title ?? "nil"), cachedDate=\(first.cachedDate?.description ?? "nil")")
                }
            }

            // Convert entities to Bookmark domain objects using mapper
            let bookmarks = entities.compactMap { $0.toDomain() }
            self.logger.info("📊 Successfully mapped \(bookmarks.count) bookmarks to domain objects")
            return bookmarks
        }
    }

    // MARK: - Cache Statistics

    func getCachedArticlesCount() -> Int {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")

        do {
            return try coreDataManager.context.count(for: fetchRequest)
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

        // Collect image URLs before clearing
        let imageURLsToDelete = try await context.perform {
            let entities = try context.fetch(fetchRequest)
            // swiftlint:disable:next discouraged_optional_collection
            return entities.compactMap { entity -> [URL]? in
                guard let imageURLsString = entity.imageURLs else { return nil }
                return imageURLsString
                    .split(separator: ",")
                    .compactMap { URL(string: String($0)) }
            }
            .flatMap(\.self)
        }

        // Clear Core Data cache
        try await context.perform { [weak self] in
            guard let self else { return }

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

        // Clear Kingfisher cache for these images
        logger.info("Clearing Kingfisher cache for \(imageURLsToDelete.count) images")
        await withTaskGroup(of: Void.self) { group in
            for url in imageURLsToDelete {
                group.addTask {
                    try? await KingfisherManager.shared.cache.removeImage(forKey: url.cacheKey)
                }
            }
        }
        logger.info("✅ Kingfisher cache cleared for offline images")
    }

    func cleanupOldestCachedArticles(keepCount: Int) async throws {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "htmlContent != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: true)]

        let context = coreDataManager.context

        // 1. Collect image URLs from articles that will be deleted
        let imageURLsToDelete = try await context.perform {
            let allEntities = try context.fetch(fetchRequest)
            if allEntities.count > keepCount {
                let entitiesToDelete = allEntities.prefix(allEntities.count - keepCount)
                // swiftlint:disable:next discouraged_optional_collection
                return entitiesToDelete.compactMap { entity -> [URL]? in
                    guard let imageURLsString = entity.imageURLs else { return nil }
                    return imageURLsString
                        .split(separator: ",")
                        .compactMap { URL(string: String($0)) }
                }
                .flatMap(\.self)
            }
            return []
        }

        // 2. Clear Core Data cache
        try await context.perform { [weak self] in
            guard let self else { return }

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

        // 3. Clear Kingfisher cache for deleted images
        if !imageURLsToDelete.isEmpty {
            logger.info("Clearing Kingfisher cache for \(imageURLsToDelete.count) images from cleanup")
            await withTaskGroup(of: Void.self) { group in
                for url in imageURLsToDelete {
                    group.addTask {
                        try? await KingfisherManager.shared.cache.removeImage(forKey: url.cacheKey)
                    }
                }
            }
        }
    }

    // MARK: - Private Helper Methods

    private func saveBookmarkToCache(bookmark: Bookmark, html: String, saveImages: Bool) async throws {
        let context = coreDataManager.context

        try await context.perform { [weak self] in
            guard let self else { return }

            let entity = try self.findOrCreateEntity(for: bookmark.id, in: context)
            bookmark.updateEntity(entity)
            self.updateEntityWithCacheData(entity: entity, bookmark: bookmark, html: html, saveImages: saveImages)

            try context.save()
            self.logger.info("💾 Saved bookmark \(bookmark.id) to Core Data with HTML (\(html.utf8.count) bytes)")

            // Verify it was saved
            let verifyRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            verifyRequest.predicate = NSPredicate(format: "id == %@ AND htmlContent != nil", bookmark.id)
            if let count = try? context.count(for: verifyRequest) {
                self.logger.info("✅ Verification: \(count) bookmark(s) with id '\(bookmark.id)' found in Core Data after save")
            }
        }
    }

    private func findOrCreateEntity(for bookmarkId: String, in context: NSManagedObjectContext) throws -> BookmarkEntity {
        let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", bookmarkId)
        fetchRequest.fetchLimit = 1

        let existingEntities = try context.fetch(fetchRequest)
        return existingEntities.first ?? BookmarkEntity(context: context)
    }

    private func updateEntityWithCacheData(entity: BookmarkEntity, bookmark: Bookmark, html: String, saveImages: Bool) {
        entity.htmlContent = html
        entity.cachedDate = Date()
        entity.lastAccessDate = Date()
        entity.cacheSize = Int64(html.utf8.count)

        // Note: imageURLs are now embedded in HTML as Base64, so we don't store them separately
        // We still track hero/thumbnail URLs for cleanup purposes
        if saveImages {
            var imageURLs: [String] = []

            // Add hero/thumbnail image if available
            if let heroImageUrl = bookmark.resources.image?.src {
                imageURLs.append(heroImageUrl)
                logger.debug("Tracking hero image for cleanup: \(heroImageUrl)")
            } else if let thumbnailUrl = bookmark.resources.thumbnail?.src {
                imageURLs.append(thumbnailUrl)
                logger.debug("Tracking thumbnail image for cleanup: \(thumbnailUrl)")
            }

            if !imageURLs.isEmpty {
                entity.imageURLs = imageURLs.joined(separator: ",")
            }
        }
    }

    private func extractImageURLsFromHTML(html: String) -> [String] {
        var imageURLs: [String] = []

        // Simple regex pattern for img tags
        let pattern = #"<img[^>]+src=\"([^\"]+)\""#

        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

            for result in results where result.numberOfRanges >= 2 {
                let urlRange = result.range(at: 1)
                if let url = nsString.substring(with: urlRange) as String? {
                    // Only include absolute URLs (http/https)
                    if url.hasPrefix("http") {
                        imageURLs.append(url)
                    }
                }
            }
        }

        logger.debug("Extracted \(imageURLs.count) image URLs from HTML")
        return imageURLs
    }

    private func embedImagesAsBase64(html: String) async -> String {
        logger.info("🔄 Starting Base64 image embedding for offline HTML")

        var modifiedHTML = html
        let imageURLs = extractImageURLsFromHTML(html: html)

        logger.info("📊 Found \(imageURLs.count) images to embed")

        var successCount = 0
        var failedCount = 0

        for (index, imageURL) in imageURLs.enumerated() {
            logger.debug("Processing image \(index + 1)/\(imageURLs.count): \(imageURL)")

            guard let url = URL(string: imageURL) else {
                logger.warning("❌ Invalid URL: \(imageURL)")
                failedCount += 1
                continue
            }

            // Try to get image from Kingfisher cache
            let result = await withCheckedContinuation { (continuation: CheckedContinuation<KFCrossPlatformImage?, Never>) in
                KingfisherManager.shared.cache.retrieveImage(forKey: url.cacheKey) { result in
                    switch result {
                    case .success(let cacheResult):
                        if let image = cacheResult.image {
                            continuation.resume(returning: image)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    case .failure(let error):
                        print("❌ Kingfisher cache retrieval error: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
            }

            guard let image = result else {
                logger.warning("❌ Image not found in Kingfisher cache: \(imageURL)")
                logger.warning("   Cache key: \(url.cacheKey)")
                failedCount += 1
                continue
            }

            // Convert image to Base64
            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                logger.warning("❌ Failed to convert image to JPEG: \(imageURL)")
                failedCount += 1
                continue
            }

            let base64String = imageData.base64EncodedString()
            let dataURI = "data:image/jpeg;base64,\(base64String)"

            // Replace URL with Base64 data URI
            let beforeLength = modifiedHTML.count
            modifiedHTML = modifiedHTML.replacingOccurrences(of: imageURL, with: dataURI)
            let afterLength = modifiedHTML.count

            if afterLength > beforeLength {
                logger.debug("✅ Embedded image \(index + 1) as Base64: \(imageURL)")
                logger.debug("   Size: \(imageData.count) bytes, Base64: \(base64String.count) chars")
                logger.debug("   HTML grew by: \(afterLength - beforeLength) chars")
                successCount += 1
            } else {
                logger.warning("⚠️ Image URL found but not replaced in HTML: \(imageURL)")
                failedCount += 1
            }
        }

        logger.info("✅ Base64 embedding complete: \(successCount) succeeded, \(failedCount) failed out of \(imageURLs.count) images")
        logger.info("📈 HTML size: \(html.utf8.count) → \(modifiedHTML.utf8.count) bytes (growth: \(modifiedHTML.utf8.count - html.utf8.count) bytes)")

        return modifiedHTML
    }

    private func prefetchImagesWithKingfisher(imageURLs: [URL]) async {
        guard !imageURLs.isEmpty else { return }

        logger.info("🔄 Starting Kingfisher prefetch for \(imageURLs.count) images")

        // Log all URLs that will be prefetched
        for (index, url) in imageURLs.enumerated() {
            logger.debug("[\(index + 1)/\(imageURLs.count)] Prefetching: \(url.absoluteString)")
            logger.debug("   Cache key: \(url.cacheKey)")
        }

        // Configure Kingfisher options for offline caching
        let options: KingfisherOptionsInfo = [
            .cacheOriginalImage,
            .diskCacheExpiration(.never), // Keep images as long as article is cached
            .backgroundDecode
        ]

        // Use Kingfisher's prefetcher with offline-friendly options
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let prefetcher = ImagePrefetcher(
                urls: imageURLs,
                options: options,
                progressBlock: { [weak self] skippedResources, failedResources, completedResources in
                    let progress = completedResources.count + failedResources.count + skippedResources.count
                    self?.logger.debug("Prefetch progress: \(progress)/\(imageURLs.count)")

                    // Log failures immediately as they happen
                    if !failedResources.isEmpty {
                        for failure in failedResources {
                            self?.logger.error("❌ Image prefetch failed: \(failure.downloadURL.absoluteString)")
                        }
                    }
                },
                completionHandler: { [weak self] skippedResources, failedResources, completedResources in
                    self?.logger.info("✅ Prefetch completed: \(completedResources.count)/\(imageURLs.count) images cached")

                    if !failedResources.isEmpty {
                        self?.logger.warning("❌ Failed to cache \(failedResources.count) images:")
                        for resource in failedResources {
                            self?.logger.warning("   - \(resource.downloadURL.absoluteString)")
                        }
                    }

                    if !skippedResources.isEmpty {
                        self?.logger.info("⏭️ Skipped \(skippedResources.count) images (already cached):")
                        for resource in skippedResources {
                            self?.logger.debug("   - \(resource.downloadURL.absoluteString)")
                        }
                    }

                    // Verify cache after prefetch
                    Task { [weak self] in
                        await self?.verifyPrefetchedImages(imageURLs)
                        continuation.resume()
                    }
                }
            )
            prefetcher.start()
        }
    }

    private func verifyPrefetchedImages(_ imageURLs: [URL]) async {
        logger.info("🔍 Verifying prefetched images in cache...")

        var cachedCount = 0
        var missingCount = 0

        for url in imageURLs {
            let isCached = await withCheckedContinuation { continuation in
                KingfisherManager.shared.cache.retrieveImage(forKey: url.cacheKey) { result in
                    switch result {
                    case .success(let cacheResult):
                        continuation.resume(returning: cacheResult.image != nil)
                    case .failure:
                        continuation.resume(returning: false)
                    }
                }
            }

            if isCached {
                cachedCount += 1
                logger.debug("✅ Verified in cache: \(url.absoluteString)")
            } else {
                missingCount += 1
                logger.warning("❌ NOT in cache after prefetch: \(url.absoluteString)")
            }
        }

        logger.info("📊 Cache verification: \(cachedCount) cached, \(missingCount) missing out of \(imageURLs.count) total")
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

    /// Caches hero/thumbnail image with a custom key for offline retrieval
    private func cacheHeroImage(url: URL, bookmarkId: String) async {
        let cacheKey = "bookmark-\(bookmarkId)-hero"
        logger.debug("Caching hero image with key: \(cacheKey)")

        // First check if already cached with custom key
        let isAlreadyCached = await withCheckedContinuation { continuation in
            ImageCache.default.retrieveImage(forKey: cacheKey) { result in
                switch result {
                case .success(let cacheResult):
                    continuation.resume(returning: cacheResult.image != nil)
                case .failure:
                    continuation.resume(returning: false)
                }
            }
        }

        if isAlreadyCached {
            logger.debug("Hero image already cached with key: \(cacheKey)")
            return
        }

        // Download and cache image with custom key
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<KFCrossPlatformImage?, Never>) in
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult.image)
                case .failure(let error):
                    self.logger.error("Failed to download hero image: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }

        if let image = result {
            // Store with custom key for offline access
            try? await ImageCache.default.store(image, forKey: cacheKey)
            logger.info("✅ Cached hero image with key: \(cacheKey)")
        } else {
            logger.warning("❌ Failed to cache hero image for bookmark: \(bookmarkId)")
        }
    }
}
