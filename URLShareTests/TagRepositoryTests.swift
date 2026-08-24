//
//  TagRepositoryTests.swift
//  URLShareTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
import CoreData

@Suite("TagRepository Tests")
struct TagRepositoryTests {
    private func fetchTags(_ context: NSManagedObjectContext) async throws -> [TagEntity] {
        try await context.perform {
            let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request)
        }
    }

    @Test("saveNewLabel creates a label with count 1")
    func createsLabel() async throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: "swift", context: context)

        let tags = try await fetchTags(context)
        #expect(tags.count == 1)
        #expect(tags[0].name == "swift")
        #expect(tags[0].count == 1)
    }

    @Test("saveNewLabel does not create a duplicate")
    func deduplicates() async throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: "swift", context: context)
        repository.saveNewLabel(name: "swift", context: context)

        #expect(try await fetchTags(context).count == 1)
    }

    @Test("saveNewLabel trims surrounding whitespace")
    func trimsWhitespace() async throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: "  swift \n", context: context)

        let tags = try await fetchTags(context)
        #expect(tags.count == 1)
        #expect(tags[0].name == "swift")
    }

    @Test("saveNewLabel ignores blank names", arguments: ["", "   ", "\n"])
    func ignoresBlank(name: String) async throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: name, context: context)

        #expect(try await fetchTags(context).isEmpty)
    }
}
