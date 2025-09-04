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
    
    func getTags() -> [String] {
        do {
            return try context.safePerform { [weak self] in
                guard let self = self else { return [] }
                
                let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                let tagEntities = try self.context.fetch(fetchRequest)
                return tagEntities.compactMap { $0.name }.sorted()
            }
        } catch {
            print("Failed to fetch tags: \(error)")
            return []
        }
    }
    
}
