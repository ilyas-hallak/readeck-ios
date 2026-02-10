import Foundation

protocol PGetLabelsUseCase {
    func execute() async throws -> [BookmarkLabel]
}

class GetLabelsUseCase: PGetLabelsUseCase {
    private let labelsRepository: PLabelsRepository
    
    init(labelsRepository: PLabelsRepository) {
        self.labelsRepository = labelsRepository
    }
    
    func execute() async throws -> [BookmarkLabel] {
        return try await labelsRepository.getLabels()
    }
} 
