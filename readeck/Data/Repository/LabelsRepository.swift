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
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "count", ascending: false),
                NSSortDescriptor(key: "name", ascending: true)
            ]

            let entities = try backgroundContext.fetch(fetchRequest)
            return entities.compactMap { entity -> BookmarkLabel? in
                guard let name = entity.name, !name.isEmpty else { return nil }
                return BookmarkLabel(
                    name: name,
                    count: Int(entity.count),
                    href: name
                )
            }
        }
    }
    
    func saveLabels(_ dtos: [BookmarkLabelDto]) async throws {
        let backgroundContext = coreDataManager.newBackgroundContext()

        try await backgroundContext.perform {
            // Batch fetch all existing labels
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.propertiesToFetch = ["name", "count"]

            let existingEntities = try backgroundContext.fetch(fetchRequest)
            var existingByName: [String: TagEntity] = [:]
            for entity in existingEntities {
                if let name = entity.name {
                    existingByName[name] = entity
                }
            }

            // Insert or update labels
            var insertCount = 0
            var updateCount = 0
            for dto in dtos {
                if let existing = existingByName[dto.name] {
                    // Update count if changed
                    if existing.count != dto.count {
                        existing.count = Int32(dto.count)
                        updateCount += 1
                    }
                } else {
                    // Insert new label
                    dto.toEntity(context: backgroundContext)
                    insertCount += 1
                }
            }

            // Only save if there are changes
            if insertCount > 0 || updateCount > 0 {
                try backgroundContext.save()
            }
        }
    }
}
