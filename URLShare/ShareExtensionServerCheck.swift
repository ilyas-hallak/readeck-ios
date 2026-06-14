import Foundation

/// Simple server check manager for Share Extension with caching
final class ShareExtensionServerCheck {
    static let shared = ShareExtensionServerCheck()

    private var cachedInfo: ServerInfoDto?
    private var lastCheckTime: Date?
    private let cacheTTL: TimeInterval = 30.0

    private init() {}

    /// Returns server info if reachable, nil otherwise.
    func checkServerReachability() async -> ServerInfoDto? {
        if let cached = getCachedResult() {
            return cached
        }

        let info = await SimpleAPI.checkServerReachability()
        updateCache(info: info)
        return info
    }

    // MARK: - Cache Management

    private func getCachedResult() -> ServerInfoDto? {
        guard let lastCheck = lastCheckTime,
              Date().timeIntervalSince(lastCheck) < cacheTTL else {
            return nil
        }
        return cachedInfo
    }

    private func updateCache(info: ServerInfoDto?) {
        cachedInfo = info
        lastCheckTime = Date()
    }
}
