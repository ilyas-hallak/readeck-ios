import Foundation

protocol TokenProvider {
    func getToken() async -> String?
    func getEndpoint() async -> String?
    func setToken(_ token: String) async
    func setEndpoint(_ endpoint: String) async
    func clearToken() async

    // OAuth methods
    func getOAuthToken() async -> OAuthToken?
    func setOAuthToken(_ token: OAuthToken) async
    func getAuthMethod() async -> AuthenticationMethod?
    func setAuthMethod(_ method: AuthenticationMethod) async
    func setOAuthClientId(_ clientId: String) async
    func getOAuthClientId() async -> String?
}

class KeychainTokenProvider: TokenProvider {
    private let keychainHelper = KeychainHelper.shared
    private let logger = Logger.network

    // Cache to avoid repeated keychain access
    private var cachedToken: String?
    private var cachedEndpoint: String?
    private var cachedOAuthToken: OAuthToken?
    private var cachedAuthMethod: AuthenticationMethod?
    private var cachedOAuthClientId: String?
    private var isRefreshing = false
    private var refreshTask: Task<OAuthToken?, Error>?

    func getToken() async -> String? {
        // Check auth method first
        if let method = await getAuthMethod(), method == .oauth {
            // Return OAuth access token if using OAuth
            if let oauthToken = await getOAuthToken() {
                // Check if token is expired or about to expire (within 5 minutes)
                if oauthToken.isExpired || willExpireSoon(oauthToken) {
                    logger.info("OAuth token expired or expiring soon, attempting refresh")
                    if let refreshedToken = await refreshOAuthTokenIfNeeded() {
                        return refreshedToken.accessToken
                    } else {
                        logger.warning("Failed to refresh OAuth token, returning expired token")
                        return oauthToken.accessToken
                    }
                }
                return oauthToken.accessToken
            }
        }

        // Otherwise return API token
        if let cached = cachedToken {
            return cached
        }

        let token = keychainHelper.loadToken()
        cachedToken = token
        return token
    }

    private func willExpireSoon(_ token: OAuthToken) -> Bool {
        guard let expiresIn = token.expiresIn else { return false }
        let expiryDate = token.createdAt.addingTimeInterval(TimeInterval(expiresIn))
        let fiveMinutesFromNow = Date().addingTimeInterval(5 * 60)
        return expiryDate < fiveMinutesFromNow
    }

    private func refreshOAuthTokenIfNeeded() async -> OAuthToken? {
        // If already refreshing, wait for that task to complete
        if let existingTask = refreshTask {
            return try? await existingTask.value
        }

        // Create new refresh task
        let task = Task<OAuthToken?, Error> {
            defer {
                self.isRefreshing = false
                self.refreshTask = nil
            }

            guard let oauthToken = await getOAuthToken(),
                  let refreshToken = oauthToken.refreshToken,
                  let endpoint = await getEndpoint(),
                  let clientId = await getOAuthClientId() else {
                logger.error("Missing required data for OAuth token refresh")
                return nil
            }

            logger.info("Refreshing OAuth token with refresh_token")

            // Import OAuthRepository here - we need to use it
            // Note: This creates a circular dependency, so we'll need to inject it or use API directly
            // For now, we'll create a minimal API call here
            do {
                let request = OAuthTokenRequestDto(
                    clientId: clientId,
                    refreshToken: refreshToken
                )

                // Create minimal API instance for token refresh
                let url = URL(string: "\(endpoint)/api/oauth/token")!
                var formData: [String: String] = [
                    "grant_type": "refresh_token",
                    "client_id": clientId,
                    "refresh_token": refreshToken
                ]

                let formBody = formData.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                    .joined(separator: "&")

                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                urlRequest.httpBody = formBody.data(using: .utf8)

                let (data, response) = try await URLSession.shared.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    logger.error("Failed to refresh OAuth token: HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    return nil
                }

                let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseDto.self, from: data)
                let newToken = OAuthToken(from: tokenResponse)

                // Save new token
                await setOAuthToken(newToken)
                logger.info("Successfully refreshed OAuth token")
                return newToken
            } catch {
                logger.error("Error refreshing OAuth token: \(error.localizedDescription)")
                return nil
            }
        }

        refreshTask = task
        isRefreshing = true
        return try? await task.value
    }

    func getEndpoint() async -> String? {
        if let cached = cachedEndpoint {
            return cached
        }

        let endpoint = keychainHelper.loadEndpoint()
        cachedEndpoint = endpoint
        return endpoint
    }

    func setToken(_ token: String) async {
        keychainHelper.saveToken(token)
        keychainHelper.saveAuthMethod(.apiToken)
        cachedAuthMethod = .apiToken
        cachedToken = token
    }

    func setEndpoint(_ endpoint: String) async {
        keychainHelper.saveEndpoint(endpoint)
        cachedEndpoint = endpoint
    }

    func clearToken() async {
        keychainHelper.clearCredentials()
        cachedToken = nil
        cachedEndpoint = nil
        cachedOAuthToken = nil
        cachedAuthMethod = nil
        cachedOAuthClientId = nil
    }

    // MARK: - OAuth Methods

    func getOAuthToken() async -> OAuthToken? {
        if let cached = cachedOAuthToken {
            return cached
        }

        let token = keychainHelper.loadOAuthToken()
        cachedOAuthToken = token
        return token
    }

    func setOAuthToken(_ token: OAuthToken) async {
        keychainHelper.saveOAuthToken(token)
        keychainHelper.saveAuthMethod(.oauth)
        cachedOAuthToken = token
        cachedAuthMethod = .oauth
    }

    func getAuthMethod() async -> AuthenticationMethod? {
        if let cached = cachedAuthMethod {
            return cached
        }

        let method = keychainHelper.loadAuthMethod()
        cachedAuthMethod = method
        return method
    }

    func setAuthMethod(_ method: AuthenticationMethod) async {
        keychainHelper.saveAuthMethod(method)
        cachedAuthMethod = method
    }

    func setOAuthClientId(_ clientId: String) async {
        keychainHelper.saveOAuthClientId(clientId)
        cachedOAuthClientId = clientId
    }

    func getOAuthClientId() async -> String? {
        if let cached = cachedOAuthClientId {
            return cached
        }

        let clientId = keychainHelper.loadOAuthClientId()
        cachedOAuthClientId = clientId
        return clientId
    }
}
