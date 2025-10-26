import Foundation
import CoreData

class LabelsRepository: PLabelsRepository, @unchecked Sendable {
    private let api: PAPI
    
    private let coreDataManager = CoreDataManager.shared
    
    init(api: PAPI) {
        self.api = api
    }
    
    func getLabels() async throws -> [BookmarkLabel] {
        // First, load from Core Data (instant response)
        let cachedLabels = try await loadLabelsFromCoreData()

        // Then sync with API in background (don't wait)
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            do {
                let dtos = try await self.api.getBookmarkLabels()
                try? await self.saveLabels(dtos)
            } catch {
                // Silent fail - we already have cached data
            }
        }

        return cachedLabels
    }

    private func loadLabelsFromCoreData() async throws -> [BookmarkLabel] {
        let backgroundContext = coreDataManager.newBackgroundContext()

        return try await backgroundContext.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let entities = try backgroundContext.fetch(fetchRequest)
            return entities.compactMap { entity -> BookmarkLabel? in
                guard let name = entity.name, !name.isEmpty else { return nil }
                return BookmarkLabel(
                    name: name,
                    count: 0,
                    href: name
                )
            }
        }
    }
    
    func saveLabels(_ dtos: [BookmarkLabelDto]) async throws {
        let backgroundContext = coreDataManager.newBackgroundContext()

        try await backgroundContext.perform {
            // Batch fetch all existing label names (much faster than individual queries)
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.propertiesToFetch = ["name"]

            let existingEntities = try backgroundContext.fetch(fetchRequest)
            let existingNames = Set(existingEntities.compactMap { $0.name })

            // Only insert new labels
            var insertCount = 0
            for dto in dtos {
                if !existingNames.contains(dto.name) {
                    dto.toEntity(context: backgroundContext)
                    insertCount += 1
                }
            }

            // Only save if there are new labels
            if insertCount > 0 {
                try backgroundContext.save()
            }
        }
    }
}
