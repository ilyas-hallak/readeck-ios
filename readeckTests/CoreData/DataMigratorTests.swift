//
//  DataMigratorTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
import CoreData
@testable import readeck

@Suite("DataMigrator Tests")
struct DataMigratorTests {

    private static let completedKey = "completedDataMigrations"

    /// Migration double that counts its runs and can be told to fail.
    private final class SpyMigration: DataMigration, @unchecked Sendable {
        enum SpyError: Error { case failed }

        let id: String
        private let shouldThrow: Bool
        private(set) var runCount = 0

        init(id: String, shouldThrow: Bool = false) {
            self.id = id
            self.shouldThrow = shouldThrow
        }

        func run(in context: NSManagedObjectContext) throws {
            runCount += 1
            if shouldThrow { throw SpyError.failed }
        }
    }

    private func makeMigrator(
        migrations: [DataMigration],
        userDefaults: UserDefaults,
        coreDataManager: CoreDataManager = .inMemory()
    ) -> DataMigrator {
        DataMigrator(
            coreDataManager: coreDataManager,
            userDefaults: userDefaults,
            migrations: migrations
        )
    }

    // MARK: - Bookkeeping

    @Test("a pending migration runs and is recorded as completed")
    func pendingMigrationRunsAndIsRecorded() async throws {
        let defaults = makeIsolatedUserDefaults()
        let migration = SpyMigration(id: "spy")

        await makeMigrator(migrations: [migration], userDefaults: defaults).runPending()

        #expect(migration.runCount == 1)
        #expect(defaults.stringArray(forKey: Self.completedKey) == ["spy"])
    }

    @Test("a migration already marked as completed does not run again")
    func completedMigrationIsSkipped() async throws {
        let defaults = makeIsolatedUserDefaults()
        defaults.set(["spy"], forKey: Self.completedKey)
        let migration = SpyMigration(id: "spy")

        await makeMigrator(migrations: [migration], userDefaults: defaults).runPending()

        #expect(migration.runCount == 0)
        #expect(defaults.stringArray(forKey: Self.completedKey) == ["spy"])
    }

    @Test("a failing migration is not recorded and is retried on the next run")
    func failingMigrationIsRetried() async throws {
        let defaults = makeIsolatedUserDefaults()
        let coreDataManager = CoreDataManager.inMemory()
        let migration = SpyMigration(id: "spy", shouldThrow: true)
        let migrator = makeMigrator(
            migrations: [migration],
            userDefaults: defaults,
            coreDataManager: coreDataManager
        )

        await migrator.runPending()

        #expect(migration.runCount == 1)
        #expect(defaults.stringArray(forKey: Self.completedKey) == nil)

        await migrator.runPending()

        #expect(migration.runCount == 2)
        #expect(defaults.stringArray(forKey: Self.completedKey) == nil)
    }

    @Test("a failing migration does not block the ones after it")
    func failingMigrationDoesNotBlockFollowing() async throws {
        let defaults = makeIsolatedUserDefaults()
        let failing = SpyMigration(id: "failing", shouldThrow: true)
        let following = SpyMigration(id: "following")

        await makeMigrator(migrations: [failing, following], userDefaults: defaults).runPending()

        #expect(failing.runCount == 1)
        #expect(following.runCount == 1)
        #expect(defaults.stringArray(forKey: Self.completedKey) == ["following"])
    }

    // MARK: - ResetAccidentalHorizontalMargin (#103)

    @Test("a margin left at the old 0 default is reset to unset, a real one is kept")
    func resetsOnlyTheAccidentalZeroMargin() async throws {
        let defaults = makeIsolatedUserDefaults()
        let coreDataManager = CoreDataManager.inMemory()
        let context = coreDataManager.context

        let accidental = SettingEntity(context: context)
        accidental.horizontalMargin = 0
        let deliberate = SettingEntity(context: context)
        deliberate.horizontalMargin = 24
        try context.save()

        await makeMigrator(
            migrations: [ResetAccidentalHorizontalMargin()],
            userDefaults: defaults,
            coreDataManager: coreDataManager
        ).runPending()

        #expect(accidental.horizontalMargin == SettingEntity.unsetHorizontalMargin)
        #expect(deliberate.horizontalMargin == 24)
        #expect(defaults.stringArray(forKey: Self.completedKey) == ["reset-accidental-horizontal-margin"])
    }
}
