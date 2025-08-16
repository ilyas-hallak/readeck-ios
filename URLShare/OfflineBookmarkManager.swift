import Foundation
import CoreData

class OfflineBookmarkManager {
    static let shared = OfflineBookmarkManager()
    
    private init() {}
    
    // MARK: - Core Data Stack for Share Extension
    
    var context: NSManagedObjectContext {
        return CoreDataManager.shared.context
    }
    
    // MARK: - Offline Storage Methods
    
    func saveOfflineBookmark(url: String, title: String = "", tags: [String] = []) -> Bool {
        let tagsString = tags.joined(separator: ",")
        
        // Check if URL already exists offline
        let fetchRequest: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "url == %@", url)
        
        do {
            let existingEntities = try context.fetch(fetchRequest)
            if let existingEntity = existingEntities.first {
                // Update existing entry
                existingEntity.tags = tagsString
                existingEntity.title = title
            } else {
                // Create new entry
                let entity = ArticleURLEntity(context: context)
                entity.id = UUID()
                entity.url = url
                entity.title = title
                entity.tags = tagsString
            }
            
            try context.save()
            print("Bookmark saved offline: \(url)")
            return true
        } catch {
            print("Failed to save offline bookmark: \(error)")
            return false
        }
    }
    
    func getTags() -> [String] {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        
        do {
            let tagEntities = try context.fetch(fetchRequest)
            return tagEntities.compactMap { $0.name }.sorted()
        } catch {
            print("Failed to fetch tags: \(error)")
            return []
        }
    }
    
}
