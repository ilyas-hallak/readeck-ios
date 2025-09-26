import Foundation
import CoreData

class LabelsRepository: PLabelsRepository, @unchecked Sendable {
    private let api: PAPI
    
    private let coreDataManager = CoreDataManager.shared
    
    init(api: PAPI) {
        self.api = api
    }
    
    func getLabels() async throws -> [BookmarkLabel] {
        let dtos = try await api.getBookmarkLabels()
        try? await saveLabels(dtos)
        return dtos.map { $0.toDomain() }
    }
    
    func saveLabels(_ dtos: [BookmarkLabelDto]) async throws {
        let backgroundContext = coreDataManager.newBackgroundContext()
        
        try await backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            for dto in dtos {
                if !self.tagExists(name: dto.name, in: backgroundContext) {
                    dto.toEntity(context: backgroundContext)
                }
            }
            try backgroundContext.save()
        }
    }
    
    private func tagExists(name: String, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
}
