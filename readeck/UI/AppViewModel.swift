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
    
    @Published var hasFinishedSetup: Bool = true
    
    init(logoutUseCase: LogoutUseCase = LogoutUseCase()) {
        self.logoutUseCase = logoutUseCase
        setupNotificationObservers()
        
        Task {
            await loadSetupStatus()
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
