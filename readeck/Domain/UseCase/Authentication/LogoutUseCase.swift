//
//  LogoutUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import Foundation

protocol PLogoutUseCase: Sendable {
    func execute() async throws
}

final class LogoutUseCase: PLogoutUseCase {
    private let authRepository: PAuthRepository
    private let settingsRepository: PSettingsRepository

    init(authRepository: PAuthRepository, settingsRepository: PSettingsRepository) {
        self.authRepository = authRepository
        self.settingsRepository = settingsRepository
    }

    func execute() async throws {
        try await authRepository.logout()
        try await settingsRepository.saveHasFinishedSetup(false)
    }
}
