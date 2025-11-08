import Foundation

protocol PSyncTagsUseCase {
    func execute() async throws
}

/// Triggers background synchronization of tags from server to Core Data
/// Uses cache-first strategy - returns immediately after triggering sync
class SyncTagsUseCase: PSyncTagsUseCase {
    private let labelsRepository: PLabelsRepository

    init(labelsRepository: PLabelsRepository) {
        self.labelsRepository = labelsRepository
    }

    func execute() async throws {
        // Trigger the sync - getLabels() uses cache-first + background sync strategy
        // We don't need the return value, just triggering the sync is enough
        _ = try await labelsRepository.getLabels()
    }
}
