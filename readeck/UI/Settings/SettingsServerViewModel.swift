import Foundation
import Observation
import SwiftUI

@Observable
class SettingsServerViewModel {
    
    // MARK: - Use Cases
    
    private let loginUseCase: PLoginUseCase
    private let logoutUseCase: PLogoutUseCase
    private let saveServerSettingsUseCase: PSaveServerSettingsUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    
    // MARK: - Server Settings
    var endpoint = ""
    var username = ""
    var password = ""
    var isLoading = false
    var isLoggedIn = false
    
    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?
    
    private var hasFinishedSetup: Bool {
        SettingsRepository().hasFinishedSetup
    }
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.loginUseCase = factory.makeLoginUseCase()
        self.logoutUseCase = factory.makeLogoutUseCase()
        self.saveServerSettingsUseCase = factory.makeSaveServerSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    var isSetupMode: Bool {
        !hasFinishedSetup
    }
    
    @MainActor
    func loadServerSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                endpoint = settings.endpoint ?? ""
                username = settings.username ?? ""
                password = settings.password ?? ""
                isLoggedIn = settings.isLoggedIn
            }
        } catch {
            errorMessage = "Error loading settings"
        }
    }
    
    @MainActor
    func saveServerSettings() async {
        guard canLogin else {
            errorMessage = "Please fill in all fields."
            return
        }
        clearMessages()
        isLoading = true
        defer { isLoading = false }
        do {
            // Normalize endpoint before saving
            let normalizedEndpoint = normalizeEndpoint(endpoint)

            let user = try await loginUseCase.execute(endpoint: normalizedEndpoint, username: username.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            try await saveServerSettingsUseCase.execute(endpoint: normalizedEndpoint, username: username, password: password, token: user.token)

            // Update local endpoint with normalized version
            endpoint = normalizedEndpoint

            isLoggedIn = true
            successMessage = "Server settings saved and successfully logged in."
            try await SettingsRepository().saveHasFinishedSetup(true)
            NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
        } catch {
            errorMessage = "Connection or login failed: \(error.localizedDescription)"
            isLoggedIn = false
        }
    }

    // MARK: - Endpoint Normalization

    private func normalizeEndpoint(_ endpoint: String) -> String {
        var normalized = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove query parameters
        if let queryIndex = normalized.firstIndex(of: "?") {
            normalized = String(normalized[..<queryIndex])
        }

        // Parse URL components
        guard var urlComponents = URLComponents(string: normalized) else {
            // If parsing fails, try adding https:// and parse again
            normalized = "https://" + normalized
            guard var urlComponents = URLComponents(string: normalized) else {
                return normalized
            }
            return buildNormalizedURL(from: urlComponents)
        }

        return buildNormalizedURL(from: urlComponents)
    }

    private func buildNormalizedURL(from components: URLComponents) -> String {
        var urlComponents = components

        // Ensure scheme is http or https, default to https
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        } else if urlComponents.scheme != "http" && urlComponents.scheme != "https" {
            urlComponents.scheme = "https"
        }

        // Remove trailing slash from path if present
        if urlComponents.path.hasSuffix("/") {
            urlComponents.path = String(urlComponents.path.dropLast())
        }

        // Remove query parameters (already done above, but double check)
        urlComponents.query = nil
        urlComponents.fragment = nil

        return urlComponents.string ?? components.string ?? ""
    }
    
    @MainActor
    func logout() async {
        do {
            try await logoutUseCase.execute()
            isLoggedIn = false
            successMessage = "Logged out"
            NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
        } catch {
            errorMessage = "Error logging out"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    var canLogin: Bool {
        !username.isEmpty && !password.isEmpty
    }
} 
