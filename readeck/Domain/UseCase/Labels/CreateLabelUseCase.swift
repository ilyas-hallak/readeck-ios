import Foundation

protocol PCreateLabelUseCase: Sendable {
    func execute(name: String) async throws
}

final class CreateLabelUseCase: PCreateLabelUseCase {
    private let labelsRepository: PLabelsRepository

    init(labelsRepository: PLabelsRepository) {
        self.labelsRepository = labelsRepository
    }

    func execute(name: String) async throws {
        try await labelsRepository.saveNewLabel(name: name)
    }
}
