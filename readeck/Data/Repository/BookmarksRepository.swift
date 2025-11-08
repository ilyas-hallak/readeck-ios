import Foundation
import CoreData
import Kingfisher

class BookmarksRepository: PBookmarksRepository {
    private var api: PAPI
    private let coreDataManager = CoreDataManager.shared
    private let logger = Logger.sync

    init(api: PAPI) {
        self.api = api
    }
    
    func fetchBookmarks(state: BookmarkState? = nil, limit: Int? = nil, offset: Int? = nil, search: String? = nil, type: [BookmarkType]? = nil, tag: String? = nil) async throws -> BookmarksPage {
        let bookmarkDtos = try await api.getBookmarks(state: state, limit: limit, offset: offset, search: search, type: type, tag: tag)
        return bookmarkDtos.toDomain()
    }
    
    func fetchBookmark(id: String) async throws -> BookmarkDetail {
        let bookmarkDetailDto = try await api.getBookmark(id: id)
        return BookmarkDetail(
            id: bookmarkDetailDto.id,
            title: bookmarkDetailDto.title,
            url: bookmarkDetailDto.url,
            description: bookmarkDetailDto.description,
            siteName: bookmarkDetailDto.siteName,
            authors: bookmarkDetailDto.authors,
            created: bookmarkDetailDto.created,
            updated: bookmarkDetailDto.updated,
            wordCount: bookmarkDetailDto.wordCount,
            readingTime: bookmarkDetailDto.readingTime,
            hasArticle: bookmarkDetailDto.hasArticle,
            isMarked: bookmarkDetailDto.isMarked,
            isArchived: bookmarkDetailDto.isArchived,
            labels: bookmarkDetailDto.labels,
            thumbnailUrl: bookmarkDetailDto.resources.thumbnail?.src ?? "",
            imageUrl: bookmarkDetailDto.resources.image?.src ?? "",
            lang: bookmarkDetailDto.lang ?? "",
            readProgress: bookmarkDetailDto.readProgress
        )
    }
    
    func fetchBookmarkArticle(id: String) async throws -> String {
        return try await api.getBookmarkArticle(id: id)
    }
    
    func createBookmark(createRequest: CreateBookmarkRequest) async throws -> String {
        let dto = CreateBookmarkRequestDto(
            url: createRequest.url,
            title: createRequest.title,
            labels: createRequest.labels
        )
        
        let response = try await api.createBookmark(createRequest: dto)
        
        // Prüfe ob die Erstellung erfolgreich war
        guard response.status == 0 || response.status == 202 else {
            throw CreateBookmarkError.serverError(response.message)
        }
        
        return response.message
    }
    
    func deleteBookmark(id: String) async throws {
        try await api.deleteBookmark(id: id)
    }
    
    func updateBookmark(id: String, updateRequest: BookmarkUpdateRequest) async throws {
        let dto = UpdateBookmarkRequestDto(
            addLabels: updateRequest.addLabels,
            isArchived: updateRequest.isArchived,
            isDeleted: updateRequest.isDeleted,
            isMarked: updateRequest.isMarked,
            labels: updateRequest.labels,
            readAnchor: updateRequest.readAnchor,
            readProgress: updateRequest.readProgress,
            removeLabels: updateRequest.removeLabels,
            title: updateRequest.title
        )
        
        try await api.updateBookmark(id: id, updateRequest: dto)
    }
    
    func searchBookmarks(search: String) async throws -> BookmarksPage {
        try await api.searchBookmarks(search: search).toDomain()
    }

    // MARK: - Offline Cache Methods

    func cacheBookmarkWithMetadata(bookmark: Bookmark, html: String, saveImages: Bool) async throws {
        // Check if already cached
        if hasCachedArticle(id: bookmark.id) {
            logger.debug("Bookmark \(bookmark.id) is already cached, skipping")
            return
        }

        let context = coreDataManager.context

        try await context.perform { [weak self] in
            guard let self = self else { return }

            // Find or create BookmarkEntity
            let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookmark.id)
            fetchRequest.fetchLimit = 1

            let existingEntities = try context.fetch(fetchRequest)
            let entity = existingEntities.first ?? BookmarkEntity(context: context)

            // Populate entity from bookmark using existing mapper
            bookmark.updateEntity(entity)

            // Set cache-specific fields
            entity.htmlContent = html
            entity.cachedDate = Date()
            entity.lastAccessDate = Date()
            entity.cacheSize = Int64(html.utf8.count)

            // Extract and save image URLs if needed
            if saveImages {
                let imageURLs = self.extractImageURLsFromHTML(html: html)
                if !imageURLs.isEmpty {
                    entity.imageURLs = imageURLs.joined(separator: ",")
                    self.logger.debug("Found \(imageURLs.count) images for bookmark \(bookmark.id)")
                }
            }

            try context.save()
            self.logger.info("Cached bookmark \(bookmark.id) with HTML (\(html.utf8.count) bytes)")
        }

        // Prefetch images with Kingfisher (outside of CoreData context)
        if saveImages, let entity = try? await getCachedEntity(id: bookmark.id), let imageURLsString = entity.imageURLs {
            let imageURLs = imageURLsString.split(separator: ",").compactMap { URL(string: String($0)) }
            if !imageURLs.isEmpty {
                await prefetchImagesWithKingfisher(imageURLs: imageURLs)
            }
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

            // Convert entities to Bookmark domain objects
            return entities.compactMap { entity -> Bookmark? in
                guard let id = entity.id,
                      let title = entity.title,
                      let url = entity.url,
                      let href = entity.href,
                      let created = entity.created,
                      let update = entity.update,
                      let siteName = entity.siteName,
                      let site = entity.site else {
                    return nil
                }

                // Create BookmarkResources (simplified for now)
                let resources = BookmarkResources(
                    article: nil,
                    icon: nil,
                    image: nil,
                    log: nil,
                    props: nil,
                    thumbnail: nil
                )

                return Bookmark(
                    id: id,
                    title: title,
                    url: url,
                    href: href,
                    description: entity.desc ?? "",
                    authors: entity.authors?.components(separatedBy: ",") ?? [],
                    created: created,
                    published: entity.published,
                    updated: update,
                    siteName: siteName,
                    site: site,
                    readingTime: Int(entity.readingTime),
                    wordCount: Int(entity.wordCount),
                    hasArticle: entity.hasArticle,
                    isArchived: entity.isArchived,
                    isDeleted: entity.hasDeleted,
                    isMarked: entity.isMarked,
                    labels: [],
                    lang: entity.lang,
                    loaded: entity.loaded,
                    readProgress: Int(entity.readProgress),
                    documentType: entity.documentType ?? "",
                    state: Int(entity.state),
                    textDirection: entity.textDirection ?? "",
                    type: entity.type ?? "",
                    resources: resources
                )
            }
        }
    }

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
