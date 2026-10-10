//
//  SafeFetchTests.swift
//  readeckTests
//

import Testing
import Foundation
import CoreData
@testable import readeck

@Suite("NSManagedObjectContext safe helpers")
struct SafeFetchTests {

    private enum TestError: Error { case failed }

    @Test("safeFetch returns the objects saved on a background context")
    func safeFetchReturnsSavedObjects() throws {
        let context = CoreDataManager.inMemory().newBackgroundContext()
        try context.safePerform {
            let entity = ArticleURLEntity(context: context)
            entity.url = "https://example.com"
            try context.save()
        }

        let request: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
        let results = try context.safeFetch(request)

        #expect(results.count == 1)
        #expect(try context.safePerform { results.first?.url } == "https://example.com")
    }

    @Test("safePerform returns the value of the operation")
    func safePerformReturnsValue() throws {
        let context = CoreDataManager.inMemory().newBackgroundContext()

        let value = try context.safePerform { 42 }

        #expect(value == 42)
    }

    @Test("safePerform rethrows the error of the operation")
    func safePerformRethrows() {
        let context = CoreDataManager.inMemory().newBackgroundContext()

        #expect(throws: TestError.self) {
            try context.safePerform { throw TestError.failed }
        }
    }
}
