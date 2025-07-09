import Foundation

class GetLabelsUseCase {
    private let labelsRepository: PLabelsRepository
    
    init(labelsRepository: PLabelsRepository) {
        self.labelsRepository = labelsRepository
    }
    
    func execute() async throws -> [BookmarkLabel] {
        return try await labelsRepository.getLabels()
    }
} 
