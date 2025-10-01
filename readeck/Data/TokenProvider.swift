import Foundation

protocol TokenProvider {
    func getToken() async -> String?
    func getEndpoint() async -> String?
    func setToken(_ token: String) async
    func clearToken() async
}

class KeychainTokenProvider: TokenProvider {
    private let keychainHelper = KeychainHelper.shared
    
    // Cache to avoid repeated keychain access
    private var cachedToken: String?
    private var cachedEndpoint: String?
    
    func getToken() async -> String? {
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
        cachedToken = token
    }
    
    func clearToken() async {
        keychainHelper.clearCredentials()
        cachedToken = nil
        cachedEndpoint = nil
    }
}
