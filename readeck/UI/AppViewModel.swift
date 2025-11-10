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
    private let syncTagsUseCase: PSyncTagsUseCase

    var hasFinishedSetup: Bool = true
    var isServerReachable: Bool = false

    private var lastAppStartTagSyncTime: Date?

    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.factory = factory
        self.syncTagsUseCase = factory.makeSyncTagsUseCase()
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
        await syncTagsOnAppStart()
    }

    private func checkServerReachability() async {
        isServerReachable = await factory.makeCheckServerReachabilityUseCase().execute()
    }

    private func syncTagsOnAppStart() async {
        let now = Date()

        // Check if last sync was less than 2 minutes ago
        if let lastSync = lastAppStartTagSyncTime,
           now.timeIntervalSince(lastSync) < 120 {
            print("AppViewModel: Skipping tag sync - last sync was less than 2 minutes ago")
            return
        }

        // Sync tags from server to Core Data
        print("AppViewModel: Syncing tags on app start")
        try? await syncTagsUseCase.execute()
        lastAppStartTagSyncTime = now
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
