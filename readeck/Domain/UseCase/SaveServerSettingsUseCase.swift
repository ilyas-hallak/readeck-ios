import Foundation

protocol PSaveServerSettingsUseCase {
    func execute(endpoint: String, username: String, password: String, token: String) async throws
}

class SaveServerSettingsUseCase: PSaveServerSettingsUseCase {
    private let repository: PSettingsRepository
    
    init(repository: PSettingsRepository) {
        self.repository = repository
    }
    
    func execute(endpoint: String, username: String, password: String, token: String) async throws {
        try await repository.saveServerSettings(endpoint: endpoint, username: username, password: password, token: token)
    }
} 
