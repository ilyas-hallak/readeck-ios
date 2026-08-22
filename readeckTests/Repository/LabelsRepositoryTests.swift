//
//  LabelsRepositoryTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
import CoreData
@testable import readeck

@Suite("LabelsRepository Tests")
struct LabelsRepositoryTests {

    private func makeRepository() -> (LabelsRepository, StubAPI, CoreDataManager) {
        let api = StubAPI()
        let coreData = CoreDataManager.inMemory()
        return (LabelsRepository(api: api, coreDataManager: coreData), api, coreData)
    }

    private func fetchTags(_ coreData: CoreDataManager) throws -> [TagEntity] {
        let context = coreData.context
        return try context.performAndWait {
            let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request)
        }
    }

    // MARK: - saveLabels

    @Test("saveLabels inserts new labels with their counts")
    func saveLabelsInserts() async throws {
        let (repository, _, coreData) = makeRepository()

        try await repository.saveLabels([
            BookmarkLabelDto(name: "swift", count: 3, href: "/swift"),
            BookmarkLabelDto(name: "ios", count: 1, href: "/ios")
        ])

        let tags = try fetchTags(coreData)
        #expect(tags.count == 2)
        #expect(tags.map(\.name) == ["ios", "swift"])
        #expect(tags.first { $0.name == "swift" }?.count == 3)
    }

    @Test("saveLabels updates the count of an existing label instead of duplicating it")
    func saveLabelsUpdatesExisting() async throws {
        let (repository, _, coreData) = makeRepository()

        try await repository.saveLabels([BookmarkLabelDto(name: "swift", count: 3, href: "/swift")])
        try await repository.saveLabels([BookmarkLabelDto(name: "swift", count: 7, href: "/swift")])

        let tags = try fetchTags(coreData)
        #expect(tags.count == 1)
        #expect(tags.first?.count == 7)
    }

    // MARK: - saveNewLabel

    @Test("saveNewLabel creates a label with count 1")
    func saveNewLabelCreates() async throws {
        let (repository, _, coreData) = makeRepository()

        try await repository.saveNewLabel(name: "kotlin")

        let tags = try fetchTags(coreData)
        #expect(tags.count == 1)
        #expect(tags.first?.name == "kotlin")
        #expect(tags.first?.count == 1)
    }

    @Test("saveNewLabel trims whitespace and ignores blank names")
    func saveNewLabelTrimsAndIgnoresBlank() async throws {
        let (repository, _, coreData) = makeRepository()

        try await repository.saveNewLabel(name: "  spaced  ")
        try await repository.saveNewLabel(name: "   ")

        let tags = try fetchTags(coreData)
        #expect(tags.count == 1)
        #expect(tags.first?.name == "spaced")
    }

    @Test("saveNewLabel does not duplicate an existing label")
    func saveNewLabelDeduplicates() async throws {
        let (repository, _, coreData) = makeRepository()

        try await repository.saveNewLabel(name: "swift")
        try await repository.saveNewLabel(name: "swift")

        #expect(try fetchTags(coreData).count == 1)
    }

    // MARK: - getLabels

    @Test("getLabels returns the cached labels sorted by count, then name")
    func getLabelsReturnsCacheSorted() async throws {
        let (repository, api, _) = makeRepository()
        // Der Hintergrund-Refresh darf den Test nicht beeinflussen.
        api.getBookmarkLabelsHandler = { [] }

        try await repository.saveLabels([
            BookmarkLabelDto(name: "rare", count: 1, href: "/rare"),
            BookmarkLabelDto(name: "common", count: 9, href: "/common"),
            BookmarkLabelDto(name: "alpha", count: 9, href: "/alpha")
        ])

        let labels = try await repository.getLabels()

        // count absteigend, bei Gleichstand name aufsteigend
        #expect(labels.map(\.name) == ["alpha", "common", "rare"])
        #expect(labels.first?.count == 9)
    }

    @Test("getLabels returns an empty list when nothing is cached")
    func getLabelsEmptyCache() async throws {
        let (repository, api, _) = makeRepository()
        api.getBookmarkLabelsHandler = { [] }

        let labels = try await repository.getLabels()

        #expect(labels.isEmpty)
    }

    @Test("getLabels still returns cached data when the background sync fails")
    func getLabelsSurvivesFailingSync() async throws {
        let (repository, api, _) = makeRepository()
        api.getBookmarkLabelsHandler = { throw APIError.serverError(500) }

        try await repository.saveLabels([BookmarkLabelDto(name: "swift", count: 2, href: "/swift")])
        let labels = try await repository.getLabels()

        #expect(labels.map(\.name) == ["swift"])
    }
}
