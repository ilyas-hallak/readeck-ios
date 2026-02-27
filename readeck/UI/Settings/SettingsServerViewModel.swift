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
    private let getServerInfoUseCase: PGetServerInfoUseCase
    private let loginWithOAuthUseCase: PLoginWithOAuthUseCase
    private let authRepository: PAuthRepository
    private let settingsRepository: PSettingsRepository

    // MARK: - Server Settings
    var endpoint = ""
    var username = ""
    var password = ""
    var isLoading = false
    var isLoggedIn = false

    // MARK: - OAuth Support
    var serverSupportsOAuth = false

    
    var customHeaders: [String: String] = [:]
    var showingHeadersSection = false
    
    var editingHeaderKey: String? = nil
    var editingHeaderKeyValue: String = ""
    var editingHeaderValue: String = ""
    
    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?

    private var hasFinishedSetup: Bool {
        settingsRepository.hasFinishedSetup
    }

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.loginUseCase = factory.makeLoginUseCase()
        self.logoutUseCase = factory.makeLogoutUseCase()
        self.saveServerSettingsUseCase = factory.makeSaveServerSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
        self.getServerInfoUseCase = factory.makeGetServerInfoUseCase()
        self.loginWithOAuthUseCase = factory.makeLoginWithOAuthUseCase()
        self.authRepository = factory.makeAuthRepository()
        self.settingsRepository = factory.makeSettingsRepository()
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
            // Load custom headers from Keychain
            if let headers = KeychainHelper.shared.loadCustomHeaders() {
                customHeaders = headers
            } else {
                customHeaders = [:]
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
            let normalizedEndpoint = EndpointValidator.normalize(endpoint)

            // Save custom headers to Keychain BEFORE login so they're available during login
            _ = KeychainHelper.shared.saveCustomHeaders(customHeaders)

            let user = try await loginUseCase.execute(endpoint: normalizedEndpoint, username: username.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            try await saveServerSettingsUseCase.execute(endpoint: normalizedEndpoint, username: username, password: password, token: user.token)

            // Update local endpoint with normalized version
            endpoint = normalizedEndpoint

            isLoggedIn = true
            successMessage = "Server settings saved and successfully logged in."
            try await settingsRepository.saveHasFinishedSetup(true)
            NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
        } catch {
            errorMessage = "Connection or login failed: \(error.localizedDescription)"
            isLoggedIn = false
        }
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

    // MARK: - OAuth Methods

    @MainActor
    func checkServerOAuthSupport() async {
        guard !endpoint.isEmpty else {
            serverSupportsOAuth = false
            return
        }

        let normalizedEndpoint = EndpointValidator.normalize(endpoint)

        do {
            let serverInfo = try await getServerInfoUseCase.execute(endpoint: normalizedEndpoint)
            serverSupportsOAuth = serverInfo.supportsOAuth
        } catch {
            serverSupportsOAuth = false
        }
    }

    @MainActor
    func loginWithOAuth() async {
        guard !endpoint.isEmpty else {
            errorMessage = "Please enter a server endpoint."
            return
        }

        clearMessages()
        isLoading = true
        defer { isLoading = false }

        do {
            let normalizedEndpoint = EndpointValidator.normalize(endpoint)
            
            // Save custom headers to Keychain BEFORE OAuth login so they're available during the OAuth flow
            _ = KeychainHelper.shared.saveCustomHeaders(customHeaders)
            
            let (token, clientId) = try await loginWithOAuthUseCase.execute(endpoint: normalizedEndpoint)

            // Save OAuth token, client ID and mark as logged in
            try await authRepository.loginWithOAuth(endpoint: normalizedEndpoint, token: token, clientId: clientId)

            // Update local endpoint with normalized version
            endpoint = normalizedEndpoint

            isLoggedIn = true
            successMessage = "Successfully logged in with OAuth."
            try await settingsRepository.saveHasFinishedSetup(true)
            NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
        } catch {
            errorMessage = "OAuth login failed: \(error.localizedDescription)"
            isLoggedIn = false
        }
    }
    
    @MainActor
    func addHeader(key: String, value: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty && HTTPHeadersHelper.isHeaderNameAllowed(trimmedKey) else {
            return
        }
        var newHeaders = customHeaders
        newHeaders[trimmedKey] = value
        customHeaders = newHeaders
    }
    
    @MainActor
    func removeHeader(key: String) {
        var newHeaders = customHeaders
        newHeaders.removeValue(forKey: key)
        customHeaders = newHeaders
    }
    
    @MainActor
    func updateHeader(key: String, value: String) {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty && HTTPHeadersHelper.isHeaderNameAllowed(trimmedKey) else {
            return
        }
        var newHeaders = customHeaders
        newHeaders[trimmedKey] = value
        customHeaders = newHeaders
    }
    
    // MARK: - Header Editing Methods
    
    @MainActor
    func startEditingHeader(key: String) {
        editingHeaderKey = key
        editingHeaderKeyValue = key
        editingHeaderValue = customHeaders[key] ?? ""
    }
    
    @MainActor
    func cancelEditingHeader() {
        editingHeaderKey = nil
        editingHeaderKeyValue = ""
        editingHeaderValue = ""
    }
    
    @MainActor
    func finishEditingHeader(originalKey: String, newKey: String, newValue: String) {
        if newKey != originalKey {
            removeHeader(key: originalKey)
            addHeader(key: newKey, value: newValue)
        } else {
            updateHeader(key: originalKey, value: newValue)
        }
        cancelEditingHeader()
    }
}
