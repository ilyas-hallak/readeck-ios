import Foundation

protocol PGetLabelsUseCase: Sendable {
    func execute() async throws -> [BookmarkLabel]
}

final class GetLabelsUseCase: PGetLabelsUseCase {
    private let labelsRepository: PLabelsRepository

    init(labelsRepository: PLabelsRepository) {
        self.labelsRepository = labelsRepository
    }

    func execute() async throws -> [BookmarkLabel] {
        try await labelsRepository.getLabels()
    }
}
