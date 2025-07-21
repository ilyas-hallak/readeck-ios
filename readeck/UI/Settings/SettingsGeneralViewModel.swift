import Foundation
import Observation
import SwiftUI

@Observable
class SettingsGeneralViewModel {
    private let saveSettingsUseCase: PSaveSettingsUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    
    // MARK: - UI Settings
    var selectedTheme: Theme = .system
    // MARK: - Sync Settings
    var autoSyncEnabled: Bool = true
    var syncInterval: Int = 15
    // MARK: - Reading Settings
    var enableReaderMode: Bool = false
    var enableTTS: Bool = false
    var openExternalLinksInApp: Bool = true
    var autoMarkAsRead: Bool = false
    
    // MARK: - Messages
    
    var errorMessage: String?
    var successMessage: String?
    
    // MARK: - Data Management (Placeholder)

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    @MainActor
    func loadGeneralSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                enableTTS = settings.enableTTS ?? false
                selectedTheme = .system
                autoSyncEnabled = false
            }
        } catch {
            errorMessage = "Error loading settings"
        }
    }
    
    @MainActor
    func saveGeneralSettings() async {
        do {
            try await saveSettingsUseCase.execute(enableTTS: enableTTS)
            successMessage = "Settings saved"
        } catch {
            errorMessage = "Error saving settings"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
} 
