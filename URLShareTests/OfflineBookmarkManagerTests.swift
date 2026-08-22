//
//  OfflineBookmarkManagerTests.swift
//  URLShareTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
import CoreData

@Suite("OfflineBookmarkManager Tests")
struct OfflineBookmarkManagerTests {
    private func makeManager() -> (OfflineBookmarkManager, CoreDataManager) {
        let coreData = TestCoreData.makeManager()
        return (OfflineBookmarkManager(coreDataManager: coreData), coreData)
    }

    private func fetchBookmarks(_ coreData: CoreDataManager) async throws -> [ArticleURLEntity] {
        let context = coreData.context
        return try await context.perform {
            let request: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
            return try context.fetch(request)
        }
    }

    private func fetchTags(_ coreData: CoreDataManager) async throws -> [TagEntity] {
        let context = coreData.context
        return try await context.perform {
            let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request)
        }
    }

    // MARK: - Offline Store

    @Test("saveOfflineBookmark queues a bookmark with its tags and HTML")
    func saveCreatesEntry() async throws {
        let (manager, coreData) = makeManager()

        let saved = manager.saveOfflineBookmark(
            url: "https://example.com/a",
            title: "Article A",
            tags: ["swift", "ios"],
            html: "<p>content</p>"
        )

        #expect(saved == true)
        let entities = try await fetchBookmarks(coreData)
        #expect(entities.count == 1)
        #expect(entities[0].url == "https://example.com/a")
        #expect(entities[0].title == "Article A")
        // Tags werden als kommaseparierter String abgelegt - so liest sie OfflineSyncManager wieder ein.
        #expect(entities[0].tags == "swift,ios")
        #expect(entities[0].html == "<p>content</p>")
        #expect(entities[0].id != nil)
    }

    @Test("saveOfflineBookmark updates the existing entry for a known URL instead of duplicating")
    func saveDeduplicatesByURL() async throws {
        let (manager, coreData) = makeManager()

        _ = manager.saveOfflineBookmark(url: "https://example.com/a", title: "Old", tags: ["old"], html: "<p>old</p>")
        _ = manager.saveOfflineBookmark(url: "https://example.com/a", title: "New", tags: ["new"], html: "<p>new</p>")

        let entities = try await fetchBookmarks(coreData)
        #expect(entities.count == 1)
        #expect(entities[0].title == "New")
        #expect(entities[0].tags == "new")
        #expect(entities[0].html == "<p>new</p>")
    }

    @Test("saveOfflineBookmark keeps separate entries for different URLs")
    func saveKeepsDistinctURLs() async throws {
        let (manager, coreData) = makeManager()

        _ = manager.saveOfflineBookmark(url: "https://example.com/a", title: "A")
        _ = manager.saveOfflineBookmark(url: "https://example.com/b", title: "B")

        let entities = try await fetchBookmarks(coreData)
        #expect(entities.count == 2)
        #expect(entities.map(\.url) == ["https://example.com/a", "https://example.com/b"])
    }

    @Test("saveOfflineBookmark stores empty tags as an empty string")
    func saveWithoutTags() async throws {
        let (manager, coreData) = makeManager()

        _ = manager.saveOfflineBookmark(url: "https://example.com/a", title: "A")

        let entities = try await fetchBookmarks(coreData)
        #expect(entities[0].tags?.isEmpty == true)
        #expect(entities[0].html == nil)
    }

    // MARK: - Sync Handoff

    @Test("a queued bookmark carries everything the sync needs")
    func queuedEntryIsSyncReady() async throws {
        let (manager, coreData) = makeManager()

        _ = manager.saveOfflineBookmark(
            url: "https://example.com/a", title: "A", tags: ["x", "y"], html: "<p>h</p>"
        )

        let entity = try #require(try await fetchBookmarks(coreData).first)
        // Genau diese Felder liest OfflineSyncManager in der Haupt-App aus.
        let tags = entity.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        #expect(entity.url == "https://example.com/a")
        #expect(tags == ["x", "y"])
        #expect(entity.html == "<p>h</p>")
    }

    // MARK: - Tags

    @Test("getTags returns the stored tag names sorted")
    func getTagsSorted() async throws {
        let (manager, _) = makeManager()

        await manager.saveTags(["swift", "android", "ios"])

        #expect(await manager.getTags() == ["android", "ios", "swift"])
    }

    @Test("getTags is empty when nothing is stored")
    func getTagsEmpty() async throws {
        let (manager, _) = makeManager()

        #expect(await manager.getTags().isEmpty)
    }

    @Test("saveTags does not insert duplicates")
    func saveTagsDeduplicates() async throws {
        let (manager, coreData) = makeManager()

        await manager.saveTags(["swift", "ios"])
        await manager.saveTags(["swift", "kotlin"])

        let tags = try await fetchTags(coreData)
        #expect(tags.map(\.name) == ["ios", "kotlin", "swift"])
    }

    @Test("saveTagsWithCount inserts new tags with their counts")
    func saveTagsWithCountInserts() async throws {
        let (manager, coreData) = makeManager()

        await manager.saveTagsWithCount([
            BookmarkLabelDto(name: "swift", count: 5, href: "/swift"),
            BookmarkLabelDto(name: "ios", count: 2, href: "/ios")
        ])

        let tags = try await fetchTags(coreData)
        #expect(tags.count == 2)
        #expect(tags.first { $0.name == "swift" }?.count == 5)
        #expect(tags.first { $0.name == "ios" }?.count == 2)
    }

    @Test("saveTagsWithCount updates the count of a known tag")
    func saveTagsWithCountUpdates() async throws {
        let (manager, coreData) = makeManager()

        await manager.saveTagsWithCount([BookmarkLabelDto(name: "swift", count: 5, href: "/swift")])
        await manager.saveTagsWithCount([BookmarkLabelDto(name: "swift", count: 11, href: "/swift")])

        let tags = try await fetchTags(coreData)
        #expect(tags.count == 1)
        #expect(tags[0].count == 11)
    }
}
