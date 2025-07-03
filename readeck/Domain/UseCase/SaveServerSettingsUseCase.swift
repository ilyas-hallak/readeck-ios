import Foundation

class SaveServerSettingsUseCase {
    private let repository: PSettingsRepository
    
    init(repository: PSettingsRepository) {
        self.repository = repository
    }
    
    func execute(endpoint: String, username: String, password: String, token: String) async throws {
        try await repository.saveServerSettings(endpoint: endpoint, username: username, password: password, token: token)
    }
} 