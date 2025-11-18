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
        syncOfflineArticlesIfNeeded()
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

    private func syncOfflineArticlesIfNeeded() {
        // Run offline sync in background without blocking app start
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }

            do {
                let settings = try await self.settingsRepository.loadOfflineSettings()

                guard settings.shouldSyncOnAppStart else {
                    Logger.sync.debug("Offline sync not needed (disabled or synced recently)")
                    return
                }

                Logger.sync.info("Auto-sync triggered on app start")
                let offlineCacheSyncUseCase = self.factory.makeOfflineCacheSyncUseCase()
                await offlineCacheSyncUseCase.syncOfflineArticles(settings: settings)
            } catch {
                Logger.sync.error("Failed to load offline settings for auto-sync: \(error.localizedDescription)")
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
