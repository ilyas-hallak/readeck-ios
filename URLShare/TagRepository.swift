import Foundation
import CoreData

/// Simple repository for managing tags in Share Extension
class TagRepository {

    private let logger = Logger.data

    /// Saves a new label to Core Data if it doesn't already exist
    /// - Parameters:
    ///   - name: The label name to save
    ///   - context: The managed object context to use
    func saveNewLabel(name: String, context: NSManagedObjectContext) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Perform save in a synchronous block to ensure it completes before extension closes
        context.performAndWait {
            // Check if label already exists
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", trimmedName)
            fetchRequest.fetchLimit = 1

            do {
                let existingTags = try context.fetch(fetchRequest)

                // Only create if it doesn't exist
                if existingTags.isEmpty {
                    let newTag = TagEntity(context: context)
                    newTag.name = trimmedName
                    newTag.count = 1 // New label is being used immediately

                    try context.save()
                    logger.info("Successfully saved new label '\(trimmedName)' to Core Data")

                    // Force immediate persistence to disk for share extension
                    // Based on: https://www.avanderlee.com/swift/core-data-app-extension-data-sharing/
                    // 1. Process pending changes
                    context.processPendingChanges()

                    // 2. Ensure persistent store coordinator writes to disk
                    // This is critical for extensions as they may be terminated quickly
                    if context.persistentStoreCoordinator != nil {
                        // Refresh all objects to ensure changes are pushed to store
                        context.refreshAllObjects()

                        // Reset staleness interval temporarily to force immediate persistence
                        let originalStalenessInterval = context.stalenessInterval
                        context.stalenessInterval = 0
                        context.refreshAllObjects()
                        context.stalenessInterval = originalStalenessInterval

                        logger.debug("Forced context refresh to ensure persistence")
                    }
                } else {
                    logger.debug("Label '\(trimmedName)' already exists, skipping creation")
                }
            } catch {
                logger.error("Failed to save new label '\(trimmedName)': \(error.localizedDescription)")
            }
        }
    }
}
