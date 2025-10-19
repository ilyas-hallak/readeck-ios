//
//  AppViewModel.swift
//  readeck
//
//  Created by Ilyas Hallak on 27.08.25.
//

import Foundation
import SwiftUI

class AppViewModel: ObservableObject {
    private let settingsRepository = SettingsRepository()
    private let logoutUseCase: LogoutUseCase
    private let checkServerReachabilityUseCase: PCheckServerReachabilityUseCase

    @Published var hasFinishedSetup: Bool = true
    @Published var isServerReachable: Bool = false

    init(logoutUseCase: LogoutUseCase = LogoutUseCase(),
         checkServerReachabilityUseCase: PCheckServerReachabilityUseCase = DefaultUseCaseFactory.shared.makeCheckServerReachabilityUseCase()) {
        self.logoutUseCase = logoutUseCase
        self.checkServerReachabilityUseCase = checkServerReachabilityUseCase
        setupNotificationObservers()

        Task {
            await loadSetupStatus()
            await checkServerReachability()
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .unauthorizedAPIResponse,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleUnauthorizedResponse()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .setupStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadSetupStatus()
        }
    }
    
    @MainActor
    private func handleUnauthorizedResponse() async {
        print("AppViewModel: Handling 401 Unauthorized - logging out user")
        
        do {
            // Führe den Logout durch
            try await logoutUseCase.execute()
            
            // Update UI state
            loadSetupStatus()
            
            print("AppViewModel: User successfully logged out due to 401 error")
        } catch {
            print("AppViewModel: Error during logout: \(error)")
        }
    }
    
    @MainActor
    private func loadSetupStatus() {
        hasFinishedSetup = settingsRepository.hasFinishedSetup
    }

    @MainActor
    private func checkServerReachability() async {
        isServerReachable = await checkServerReachabilityUseCase.execute()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
