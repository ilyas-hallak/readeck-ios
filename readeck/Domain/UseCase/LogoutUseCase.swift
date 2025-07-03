//
//  LogoutUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import Foundation

protocol LogoutUseCaseProtocol {
    func execute() async throws
}

class LogoutUseCase: LogoutUseCaseProtocol {
    private let settingsRepository: SettingsRepository
    private let tokenManager: TokenManager
    
    init(
        settingsRepository: SettingsRepository = SettingsRepository(),
        tokenManager: TokenManager = TokenManager.shared
    ) {
        self.settingsRepository = settingsRepository
        self.tokenManager = tokenManager
    }
    
    func execute() async throws {
        // Clear the token
        try await tokenManager.clearToken()
        
        // Reset hasFinishedSetup to false
        try await settingsRepository.saveHasFinishedSetup(false)
        
        // Clear user session data
        try await settingsRepository.saveToken("")
        try await settingsRepository.saveUsername("")
        try await settingsRepository.savePassword("")
        
        KeychainHelper.shared.saveToken("")
        KeychainHelper.shared.saveEndpoint("")
        
        // Note: We keep the endpoint for potential re-login
        // but clear the authentication data
        
        print("LogoutUseCase: User logged out successfully")
    }
} 
