//
//  ServerInfoRepository.swift
//  readeck
//
//  Created by Ilyas Hallak

import Foundation

final class ServerInfoRepository: PServerInfoRepository {
    private let apiClient: PInfoApiClient
    private let logger = Logger.network

    // Cache properties
    private var cachedServerInfo: ServerInfo?
    private var lastCheckTime: Date?
    private let cacheTTL: TimeInterval = 30.0 // 30 seconds cache
    private let rateLimitInterval: TimeInterval = 5.0 // min 5 seconds between requests

    // Thread safety
    private let queue = DispatchQueue(label: "com.readeck.serverInfoRepository", attributes: .concurrent)

    init(apiClient: PInfoApiClient) {
        self.apiClient = apiClient
    }

    func checkServerReachability() async -> Bool {
        // Check cache first
        if let cached = getCachedReachability() {
            logger.debug("Server reachability from cache: \(cached)")
            return cached
        }

        // Check rate limiting
        if isRateLimited() {
            logger.debug("Server reachability check rate limited, using cached value")
            return cachedServerInfo?.isReachable ?? false
        }

        // Perform actual check
        do {
            let info = try await apiClient.getServerInfo(endpoint: nil)
            let serverInfo = ServerInfo(from: info)
            updateCache(serverInfo: serverInfo)
            logger.info("Server reachability checked: true (version: \(info.version))")
            return true
        } catch {
            let unreachableInfo = ServerInfo.unreachable
            updateCache(serverInfo: unreachableInfo)
            logger.warning("Server reachability check failed: \(error.localizedDescription)")
            return false
        }
    }

    func getServerInfo(endpoint: String? = nil) async throws -> ServerInfo {
        // Check cache first (only if no custom endpoint provided)
        if endpoint == nil, let cached = getCachedServerInfo() {
            logger.debug("Server info from cache")
            return cached
        }

        // Check rate limiting (only if no custom endpoint provided)
        if endpoint == nil, isRateLimited(), let cached = cachedServerInfo {
            logger.debug("Server info check rate limited, using cached value")
            return cached
        }

        // Fetch fresh info
        let dto = try await apiClient.getServerInfo(endpoint: endpoint)
        let serverInfo = ServerInfo(from: dto)

        // Only update cache if using default endpoint
        if endpoint == nil {
            updateCache(serverInfo: serverInfo)
        }

        logger.info("Server info fetched: version \(dto.version)")
        return serverInfo
    }

    // MARK: - Cache Management

    // swiftlint:disable:next discouraged_optional_boolean
    private func getCachedReachability() -> Bool? {
        queue.sync {
            guard let lastCheck = lastCheckTime,
                  Date().timeIntervalSince(lastCheck) < cacheTTL,
                  let cached = cachedServerInfo else {
                return nil
            }
            return cached.isReachable
        }
    }

    private func getCachedServerInfo() -> ServerInfo? {
        queue.sync {
            guard let lastCheck = lastCheckTime,
                  Date().timeIntervalSince(lastCheck) < cacheTTL,
                  let cached = cachedServerInfo else {
                return nil
            }
            return cached
        }
    }

    private func isRateLimited() -> Bool {
        queue.sync {
            guard let lastCheck = lastCheckTime else {
                return false
            }
            return Date().timeIntervalSince(lastCheck) < rateLimitInterval
        }
    }

    private func updateCache(serverInfo: ServerInfo) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cachedServerInfo = serverInfo
            self?.lastCheckTime = Date()
        }
    }
}
