import Foundation

protocol PSaveSettingsUseCase {
    func execute(endpoint: String, username: String, password: String) async throws
    func execute(endpoint: String, username: String, password: String, hasFinishedSetup: Bool) async throws
    func execute(token: String) async throws
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws
}

class SaveSettingsUseCase: PSaveSettingsUseCase {
    private let settingsRepository: PSettingsRepository
    
    init(settingsRepository: PSettingsRepository) {
        self.settingsRepository = settingsRepository
    }
    
    func execute(endpoint: String, username: String, password: String) async throws {
        try await settingsRepository.saveSettings(
            .init(
                endpoint: endpoint,
                username: username,
                password: password
            )
        )
    }
    
    func execute(endpoint: String, username: String, password: String, hasFinishedSetup: Bool) async throws {
        try await settingsRepository.saveSettings(
            .init(
                endpoint: endpoint,
                username: username,
                password: password,
                hasFinishedSetup: hasFinishedSetup
            )
        )
    }
    
    func execute(token: String) async throws {
        try await settingsRepository.saveSettings(
            .init(
                token: token
            )
        )
    }
    
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws {
        try await settingsRepository.saveSettings(
            .init(
                fontFamily: selectedFontFamily,
                fontSize: selectedFontSize
            )
        )
    }
}
