//
//  OfflineSettingsViewModel.swift
//  readeck
//
//  Created by Claude on 17.11.25.
//

import Foundation
import Observation
import Combine

@Observable
class OfflineSettingsViewModel {

    // MARK: - Dependencies

    private let settingsRepository: PSettingsRepository
    private let offlineCacheSyncUseCase: POfflineCacheSyncUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    var offlineSettings: OfflineSettings = OfflineSettings()
    var isSyncing: Bool = false
    var syncProgress: String?
    var cachedArticlesCount: Int = 0
    var cacheSize: String = "0 KB"

    // MARK: - Initialization

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.settingsRepository = factory.makeSettingsRepository()
        self.offlineCacheSyncUseCase = factory.makeOfflineCacheSyncUseCase()

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Bind isSyncing from UseCase
        offlineCacheSyncUseCase.isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSyncing, on: self)
            .store(in: &cancellables)

        // Bind syncProgress from UseCase
        offlineCacheSyncUseCase.syncProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.syncProgress, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    @MainActor
    func loadSettings() async {
        do {
            offlineSettings = try await settingsRepository.loadOfflineSettings()
            updateCacheStats()
            Logger.viewModel.debug("Loaded offline settings: enabled=\(offlineSettings.enabled)")
        } catch {
            Logger.viewModel.error("Failed to load offline settings: \(error.localizedDescription)")
        }
    }

    @MainActor
    func saveSettings() async {
        do {
            try await settingsRepository.saveOfflineSettings(offlineSettings)
            Logger.viewModel.debug("Saved offline settings")
        } catch {
            Logger.viewModel.error("Failed to save offline settings: \(error.localizedDescription)")
        }
    }

    @MainActor
    func syncNow() async {
        Logger.viewModel.info("Manual sync triggered")
        await offlineCacheSyncUseCase.syncOfflineArticles(settings: offlineSettings)
        // Reload settings to get updated lastSyncDate
        await loadSettings()
        updateCacheStats()
    }

    @MainActor
    func updateCacheStats() {
        cachedArticlesCount = offlineCacheSyncUseCase.getCachedArticlesCount()
        cacheSize = offlineCacheSyncUseCase.getCacheSize()
    }
}
