import CoreData
import Foundation

/// Runs the registered `DataMigration`s at app start, each one exactly once.
///
/// Completed migrations are remembered by id in UserDefaults. A migration that throws is
/// not marked as done, so it is retried on the next launch, and it does not stop the ones
/// after it in the list.
final class DataMigrator {
    /// The registry. Append new migrations at the end, never reorder or rename existing ids.
    static let allMigrations: [DataMigration] = [
        ResetAccidentalHorizontalMargin()
    ]

    private static let completedMigrationsKey = "completedDataMigrations"

    private let coreDataManager: CoreDataManager
    private let userDefaults: UserDefaults
    private let migrations: [DataMigration]
    private let logger = Logger.data

    init(
        coreDataManager: CoreDataManager = .shared,
        userDefaults: UserDefaults = .standard,
        migrations: [DataMigration] = DataMigrator.allMigrations
    ) {
        self.coreDataManager = coreDataManager
        self.userDefaults = userDefaults
        self.migrations = migrations
    }

    func runPending() async {
        var completed = userDefaults.stringArray(forKey: Self.completedMigrationsKey) ?? []
        let context = coreDataManager.context

        for migration in migrations where !completed.contains(migration.id) {
            guard await run(migration, in: context) else { continue }
            completed.append(migration.id)
            userDefaults.set(completed, forKey: Self.completedMigrationsKey)
        }
    }

    /// Returns whether the migration finished without throwing.
    private func run(_ migration: DataMigration, in context: NSManagedObjectContext) async -> Bool {
        await withCheckedContinuation { continuation in
            context.perform {
                do {
                    try migration.run(in: context)
                    if context.hasChanges {
                        try context.save()
                    }
                    self.logger.info("Data migration '\(migration.id)' completed")
                    continuation.resume(returning: true)
                } catch {
                    // Drop whatever the failed migration already changed, so a later save
                    // cannot persist a half-applied state. Migrations run before anything
                    // else touches the context, so there is nothing else to lose here.
                    context.rollback()
                    self.logger.error("Data migration '\(migration.id)' failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
