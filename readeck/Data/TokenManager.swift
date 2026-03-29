import Foundation
import OSLog

@Observable
final class TokenManager {
    static let shared = TokenManager()

    private let logger = Logger.auth
    private let settingsRepository: PSettingsRepository
    private var cachedSettings: Settings?

    private init() {
        self.settingsRepository = DefaultUseCaseFactory.shared.makeSettingsRepository()
    }

    var currentToken: String? {
        cachedSettings?.token
    }

    var currentEndpoint: String? {
        cachedSettings?.endpoint
    }

    func loadSettings() async {
        do {
            cachedSettings = try await settingsRepository.loadSettings()
        } catch {
            logger.error("Failed to load settings: \(error)")
        }
    }

    func updateToken(_ token: String) async {
        do {
            try await settingsRepository.saveToken(token)
            cachedSettings?.token = token
        } catch {
            logger.error("Failed to save token: \(error)")
        }
    }

    func clearToken() async throws {
        do {
            try await settingsRepository.saveToken("")
            cachedSettings?.token = ""
        } catch {
            logger.error("Failed to clear token: \(error)")
            throw error
        }
    }
}
