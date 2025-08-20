import Foundation
import CoreData

class LabelsRepository: PLabelsRepository {
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
        for dto in dtos {
            if !tagExists(name: dto.name) {
                dto.toEntity(context: coreDataManager.context)
            }
        }
        try coreDataManager.context.save()
    }
    
    private func tagExists(name: String) -> Bool {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        var exists = false
        coreDataManager.context.performAndWait {
            do {
                let results = try coreDataManager.context.fetch(fetchRequest)
                exists = !results.isEmpty
            } catch {
                exists = false
            }
        }
        return exists
    }
}
