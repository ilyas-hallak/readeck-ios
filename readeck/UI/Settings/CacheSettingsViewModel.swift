//
//  CacheSettingsViewModel.swift
//  readeck
//
//  Created by Claude on 01.12.25.
//

import Foundation
import Observation

@Observable
final class CacheSettingsViewModel {
    // MARK: - Dependencies

    private let getCacheSizeUseCase: PGetCacheSizeUseCase
    private let getMaxCacheSizeUseCase: PGetMaxCacheSizeUseCase
    private let updateMaxCacheSizeUseCase: PUpdateMaxCacheSizeUseCase
    private let clearCacheUseCase: PClearCacheUseCase

    // MARK: - Published State

    var cacheSize = "0 MB"
    var maxCacheSize: Double = 200 // in MB
    var isClearing = false
    var showClearAlert = false

    // MARK: - Initialization

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getCacheSizeUseCase = factory.makeGetCacheSizeUseCase()
        self.getMaxCacheSizeUseCase = factory.makeGetMaxCacheSizeUseCase()
        self.updateMaxCacheSizeUseCase = factory.makeUpdateMaxCacheSizeUseCase()
        self.clearCacheUseCase = factory.makeClearCacheUseCase()
    }

    // MARK: - Public Methods

    @MainActor
    func loadCacheSettings() async {
        await updateCacheSize()
        await loadMaxCacheSize()
    }

    @MainActor
    func updateCacheSize() async {
        do {
            let sizeInBytes = try await getCacheSizeUseCase.execute()
            let mbSize = Double(sizeInBytes) / (1024 * 1024)
            cacheSize = String(format: "%.1f MB", mbSize)
            Logger.viewModel.debug("Cache size: \(cacheSize)")
        } catch {
            cacheSize = "Unknown"
            Logger.viewModel.error("Failed to get cache size: \(error.localizedDescription)")
        }
    }

    @MainActor
    func loadMaxCacheSize() async {
        do {
            let sizeInBytes = try await getMaxCacheSizeUseCase.execute()
            maxCacheSize = Double(sizeInBytes) / (1024 * 1024)
            Logger.viewModel.debug("Max cache size: \(maxCacheSize) MB")
        } catch {
            Logger.viewModel.error("Failed to load max cache size: \(error.localizedDescription)")
        }
    }

    @MainActor
    func updateMaxCacheSize(_ newSize: Double) async {
        let bytes = UInt(newSize * 1024 * 1024)
        do {
            try await updateMaxCacheSizeUseCase.execute(sizeInBytes: bytes)
            Logger.viewModel.info("Updated max cache size to \(newSize) MB")
        } catch {
            Logger.viewModel.error("Failed to update max cache size: \(error.localizedDescription)")
        }
    }

    @MainActor
    func clearCache() async {
        isClearing = true
        do {
            try await clearCacheUseCase.execute()
            await updateCacheSize()
            Logger.viewModel.info("Cache cleared successfully")
        } catch {
            Logger.viewModel.error("Failed to clear cache: \(error.localizedDescription)")
        }
        isClearing = false
    }
}
