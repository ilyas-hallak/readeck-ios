//
//  AppViewModel.swift
//  readeck
//
//  Created by Ilyas Hallak on 27.08.25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class AppViewModel {
    private let settingsRepository: PSettingsRepository
    private let factory: UseCaseFactory
    private let syncTagsUseCase: PSyncTagsUseCase
    private let updateUnreadBadgeUseCase: PUpdateUnreadBadgeUseCase
    let networkMonitorUseCase: PNetworkMonitorUseCase

    var hasFinishedSetup = true
    var isServerReachable = false
    var isNetworkConnected = true

    private var lastAppStartTagSyncTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var notificationObservers: [Any] = []

    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.factory = factory
        self.settingsRepository = factory.makeSettingsRepository()
        self.syncTagsUseCase = factory.makeSyncTagsUseCase()
        self.updateUnreadBadgeUseCase = factory.makeUpdateUnreadBadgeUseCase()
        self.networkMonitorUseCase = factory.makeNetworkMonitorUseCase()

        setupNotificationObservers()
        setupNetworkMonitoring()
        loadSetupStatus()
    }

    private func setupNotificationObservers() {
        let unauthorizedObserver = NotificationCenter.default.addObserver(
            forName: .unauthorizedAPIResponse,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleUnauthorizedResponse()
            }
        }
        notificationObservers.append(unauthorizedObserver)

        let setupObserver = NotificationCenter.default.addObserver(
            forName: .setupStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadSetupStatus()
            }
        }
        notificationObservers.append(setupObserver)

        // Keep the unread app-icon badge in sync when items leave the unread list.
        for name in [Notification.Name.bookmarkArchived, .bookmarkDeleted] {
            let observer = NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateUnreadBadgeUseCase.refresh()
                }
            }
            notificationObservers.append(observer)
        }
    }

    private func handleUnauthorizedResponse() async {
        Logger.viewModel.info("Handling 401 Unauthorized - logging out user")

        do {
            try await factory.makeLogoutUseCase().execute()
            loadSetupStatus()

            Logger.viewModel.info("User successfully logged out due to 401 error")
        } catch {
            Logger.viewModel.error("Error during logout: \(error.localizedDescription)")
        }
    }

    private func setupNetworkMonitoring() {
        // Start monitoring network status
        networkMonitorUseCase.startMonitoring()

        // Bind network status to our published property
        networkMonitorUseCase.isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isNetworkConnected, on: self)
            .store(in: &cancellables)
    }

    func bindNetworkStatus(to appSettings: AppSettings) {
        // Bind network status to AppSettings for global access
        networkMonitorUseCase.isConnected
            .receive(on: DispatchQueue.main)
            .sink { isConnected in
                Logger.viewModel.info("🌐 Network status changed: \(isConnected ? "Connected" : "Disconnected")")
                appSettings.isNetworkConnected = isConnected
            }
            .store(in: &cancellables)
    }

    private func loadSetupStatus() {
        hasFinishedSetup = settingsRepository.hasFinishedSetup
    }

    func onAppResume() async {
        await checkServerReachability()
        await syncTagsOnAppStart()
        syncOfflineArticlesIfNeeded()
        await updateUnreadBadgeUseCase.refresh()
    }

    /// Recomputes the unread app-icon badge. Exposed for scene-phase transitions
    /// (e.g. entering background) so views don't reach into the badge use case directly.
    func refreshBadge() async {
        await updateUnreadBadgeUseCase.refresh()
    }

    private func checkServerReachability() async {
        isServerReachable = await factory.makeCheckServerReachabilityUseCase().execute()
    }

    private func syncTagsOnAppStart() async {
        // Don't sync if onboarding is not complete (no token/endpoint available)
        guard settingsRepository.hasFinishedSetup else {
            Logger.sync.debug("Skipping tag sync - onboarding not completed")
            return
        }

        let now = Date()

        // Check if last sync was less than 2 minutes ago
        if let lastSync = lastAppStartTagSyncTime,
           now.timeIntervalSince(lastSync) < 120 {
            Logger.sync.debug("Skipping tag sync - last sync was less than 2 minutes ago")
            return
        }

        // Sync tags from server to Core Data
        Logger.sync.info("Syncing tags on app start")
        try? await syncTagsUseCase.execute()
        lastAppStartTagSyncTime = now
    }

    private func syncOfflineArticlesIfNeeded() {
        // Don't sync if onboarding is not complete (no token/endpoint available)
        guard settingsRepository.hasFinishedSetup else {
            Logger.sync.debug("Skipping offline sync - onboarding not completed")
            return
        }

        // Run offline sync in background without blocking app start
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }

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
