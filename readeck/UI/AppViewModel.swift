//
//  AppViewModel.swift
//  readeck
//
//  Created by Ilyas Hallak on 27.08.25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AppViewModel {
    private let settingsRepository = SettingsRepository()
    private let factory: UseCaseFactory

    var hasFinishedSetup: Bool = true
    var isServerReachable: Bool = false

    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.factory = factory
        setupNotificationObservers()

        loadSetupStatus()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .unauthorizedAPIResponse,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleUnauthorizedResponse()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .setupStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadSetupStatus()
            }
        }
    }
    
    private func handleUnauthorizedResponse() async {
        print("AppViewModel: Handling 401 Unauthorized - logging out user")
        
        do {
            try await factory.makeLogoutUseCase().execute()
            loadSetupStatus()
            
            print("AppViewModel: User successfully logged out due to 401 error")
        } catch {
            print("AppViewModel: Error during logout: \(error)")
        }
    }
    
    private func loadSetupStatus() {
        hasFinishedSetup = settingsRepository.hasFinishedSetup
    }

    func onAppResume() async {
        await checkServerReachability()
    }

    private func checkServerReachability() async {
        isServerReachable = await factory.makeCheckServerReachabilityUseCase().execute()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
