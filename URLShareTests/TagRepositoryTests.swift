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
    private func fetchTags(_ context: NSManagedObjectContext) throws -> [TagEntity] {
        try context.performAndWait {
            let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try context.fetch(request)
        }
    }

    @Test("saveNewLabel creates a label with count 1")
    func createsLabel() throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: "swift", context: context)

        let tags = try fetchTags(context)
        #expect(tags.count == 1)
        #expect(tags[0].name == "swift")
        #expect(tags[0].count == 1)
    }

    @Test("saveNewLabel does not create a duplicate")
    func deduplicates() throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: "swift", context: context)
        repository.saveNewLabel(name: "swift", context: context)

        #expect(try fetchTags(context).count == 1)
    }

    @Test("saveNewLabel trims surrounding whitespace")
    func trimsWhitespace() throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: "  swift \n", context: context)

        let tags = try fetchTags(context)
        #expect(tags.count == 1)
        #expect(tags[0].name == "swift")
    }

    @Test("saveNewLabel ignores blank names", arguments: ["", "   ", "\n"])
    func ignoresBlank(name: String) throws {
        let context = TestCoreData.makeManager().context
        let repository = TagRepository()

        repository.saveNewLabel(name: name, context: context)

        #expect(try fetchTags(context).isEmpty)
    }
}
