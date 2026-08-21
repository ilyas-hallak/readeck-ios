//
//  CoreDataThreadingTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 21.08.26.
//
//  Verifies the issue #81 CoreData threading patterns on an isolated in-memory
//  stack (CoreDataManager.shared is a singleton bound to the App Group store).
//

import Testing
import Foundation
import CoreData
@testable import readeck

@Suite("CoreData Threading Tests")
struct CoreDataThreadingTests {

    // MARK: - Test Setup

    /// In-memory container mirroring CoreDataManager's merge configuration.
    private func makeContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        let container = NSPersistentContainer(name: "readeck", managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        #expect(loadError == nil)

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }

    /// Mirrors CoreDataManager.newBackgroundContext().
    private func makeBackgroundContext(_ container: NSPersistentContainer) -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    private func makeBookmarkEntity(in context: NSManagedObjectContext, id: String) {
        let entity = BookmarkEntity(context: context)
        entity.id = id
        entity.title = "Article \(id)"
        entity.htmlContent = "<html><body>\(id)</body></html>"
        entity.cachedDate = Date()
        entity.lastAccessDate = Date()
        entity.cacheSize = Int64(id.utf8.count)
    }

    private func totalCount(in context: NSManagedObjectContext) -> Int {
        var count = 0
        context.performAndWait {
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            count = (try? context.count(for: request)) ?? 0
        }
        return count
    }

    // MARK: - Tests

    @Test("Concurrent background writes and main-context reads stay consistent")
    func testConcurrentWritesAndReads() async {
        let container = makeContainer()
        let viewContext = container.viewContext

        let writerCount = 8
        let recordsPerWriter = 25

        await withTaskGroup(of: Void.self) { group in
            // Writers: each on its own background context.
            for writer in 0..<writerCount {
                group.addTask {
                    let context = self.makeBackgroundContext(container)
                    context.performAndWait {
                        for record in 0..<recordsPerWriter {
                            self.makeBookmarkEntity(in: context, id: "w\(writer)-r\(record)")
                        }
                        try? context.save()
                    }
                }
            }

            // Concurrent readers on the main context. These must not crash
            // while writers merge changes into the view context.
            for _ in 0..<writerCount {
                group.addTask {
                    for _ in 0..<10 {
                        _ = self.totalCount(in: viewContext)
                    }
                }
            }
        }

        // All records must be present and unique once every writer has saved.
        let expected = writerCount * recordsPerWriter
        #expect(totalCount(in: viewContext) == expected)

        var uniqueIDs = Set<String>()
        viewContext.performAndWait {
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            let entities = (try? viewContext.fetch(request)) ?? []
            uniqueIDs = Set(entities.compactMap { $0.id })
        }
        #expect(uniqueIDs.count == expected)
    }

    @Test("performAndWait-wrapped save persists and is visible via fetch")
    func testPerformAndWaitSavePersists() {
        let container = makeContainer()
        let viewContext = container.viewContext

        // Write inside performAndWait, exactly like CoreDataManager.save().
        viewContext.performAndWait {
            makeBookmarkEntity(in: viewContext, id: "persist-1")
            guard viewContext.hasChanges else { return }
            try? viewContext.save()
        }

        // A fresh background context reading the same store must see the record.
        let readContext = makeBackgroundContext(container)
        var found: String?
        readContext.performAndWait {
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", "persist-1")
            request.fetchLimit = 1
            found = (try? readContext.fetch(request))?.first?.htmlContent
        }

        #expect(found == "<html><body>persist-1</body></html>")
    }

    @Test("performAndWait is reentrant and safe when nested")
    func testNestedPerformAndWaitIsSafe() {
        let container = makeContainer()
        let viewContext = container.viewContext

        // performAndWait is reentrant; nesting on the same queue must not deadlock.
        var count = -1
        viewContext.performAndWait {
            makeBookmarkEntity(in: viewContext, id: "nested-1")
            viewContext.performAndWait {
                try? viewContext.save()
            }
            let request: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            count = (try? viewContext.count(for: request)) ?? -1
        }

        #expect(count == 1)
    }
}
