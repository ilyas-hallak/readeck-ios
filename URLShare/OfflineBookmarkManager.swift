import Foundation
import CoreData

class OfflineBookmarkManager: @unchecked Sendable {
    static let shared = OfflineBookmarkManager()
    
    private init() {}
    
    // MARK: - Core Data Stack for Share Extension
    
    var context: NSManagedObjectContext {
        return CoreDataManager.shared.context
    }
    
    // MARK: - Offline Storage Methods
    
    func saveOfflineBookmark(url: String, title: String = "", tags: [String] = []) -> Bool {
        let tagsString = tags.joined(separator: ",")
        
        do {
            try context.safePerform { [weak self] in
                guard let self = self else { return }
                
                // Check if URL already exists offline
                let fetchRequest: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "url == %@", url)
                
                let existingEntities = try self.context.fetch(fetchRequest)
                if let existingEntity = existingEntities.first {
                    // Update existing entry
                    existingEntity.tags = tagsString
                    existingEntity.title = title
                } else {
                    // Create new entry
                    let entity = ArticleURLEntity(context: self.context)
                    entity.id = UUID()
                    entity.url = url
                    entity.title = title
                    entity.tags = tagsString
                }
                
                try self.context.save()
                print("Bookmark saved offline: \(url)")
            }
            return true
        } catch {
            print("Failed to save offline bookmark: \(error)")
            return false
        }
    }
    
    func getTags() async -> [String] {
        let backgroundContext = CoreDataManager.shared.newBackgroundContext()

        do {
            return try await backgroundContext.perform {
                let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

                let tagEntities = try backgroundContext.fetch(fetchRequest)
                return tagEntities.compactMap { $0.name }
            }
        } catch {
            print("Failed to fetch tags: \(error)")
            return []
        }
    }

    func saveTags(_ tags: [String]) async {
        let backgroundContext = CoreDataManager.shared.newBackgroundContext()

        do {
            try await backgroundContext.perform {
                // Batch fetch existing tags
                let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                fetchRequest.propertiesToFetch = ["name"]

                let existingEntities = try backgroundContext.fetch(fetchRequest)
                let existingNames = Set(existingEntities.compactMap { $0.name })

                // Only insert new tags
                var insertCount = 0
                for tag in tags {
                    if !existingNames.contains(tag) {
                        let entity = TagEntity(context: backgroundContext)
                        entity.name = tag
                        entity.count = 0
                        insertCount += 1
                    }
                }

                // Only save if there are new tags
                if insertCount > 0 {
                    try backgroundContext.save()
                    print("Saved \(insertCount) new tags to Core Data")
                }
            }
        } catch {
            print("Failed to save tags: \(error)")
        }
    }

    func saveTagsWithCount(_ tags: [BookmarkLabelDto]) async {
        let backgroundContext = CoreDataManager.shared.newBackgroundContext()

        do {
            try await backgroundContext.perform {
                // Batch fetch existing tags
                let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                fetchRequest.propertiesToFetch = ["name"]

                let existingEntities = try backgroundContext.fetch(fetchRequest)
                var existingByName: [String: TagEntity] = [:]
                for entity in existingEntities {
                    if let name = entity.name {
                        existingByName[name] = entity
                    }
                }

                // Insert or update tags
                var insertCount = 0
                var updateCount = 0
                for tag in tags {
                    if let existing = existingByName[tag.name] {
                        // Update count if changed
                        if existing.count != tag.count {
                            existing.count = Int32(tag.count)
                            updateCount += 1
                        }
                    } else {
                        // Insert new tag
                        let entity = TagEntity(context: backgroundContext)
                        entity.name = tag.name
                        entity.count = Int32(tag.count)
                        insertCount += 1
                    }
                }

                // Only save if there are changes
                if insertCount > 0 || updateCount > 0 {
                    try backgroundContext.save()
                    print("Saved \(insertCount) new tags and updated \(updateCount) tags to Core Data")
                }
            }
        } catch {
            print("Failed to save tags with count: \(error)")
        }
    }
    
}
