import Foundation

/// Simple server check manager for Share Extension with caching
class ShareExtensionServerCheck {
    static let shared = ShareExtensionServerCheck()

    // Cache properties
    private var cachedResult: Bool?
    private var lastCheckTime: Date?
    private let cacheTTL: TimeInterval = 30.0

    private init() {}

    func checkServerReachability() async -> Bool {
        // Check cache first
        if let cached = getCachedResult() {
            return cached
        }

        // Use SimpleAPI for actual check
        let result = await SimpleAPI.checkServerReachability()
        updateCache(result: result)
        return result
    }

    // MARK: - Cache Management

    private func getCachedResult() -> Bool? {
        guard let lastCheck = lastCheckTime,
              Date().timeIntervalSince(lastCheck) < cacheTTL,
              let cached = cachedResult else {
            return nil
        }
        return cached
    }

    private func updateCache(result: Bool) {
        cachedResult = result
        lastCheckTime = Date()
    }
}
