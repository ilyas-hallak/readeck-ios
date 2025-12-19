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
}

class KeychainTokenProvider: TokenProvider {
    private let keychainHelper = KeychainHelper.shared

    // Cache to avoid repeated keychain access
    private var cachedToken: String?
    private var cachedEndpoint: String?
    private var cachedOAuthToken: OAuthToken?
    private var cachedAuthMethod: AuthenticationMethod?

    func getToken() async -> String? {
        // Check auth method first
        if let method = await getAuthMethod(), method == .oauth {
            // Return OAuth access token if using OAuth
            if let oauthToken = await getOAuthToken() {
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
}
