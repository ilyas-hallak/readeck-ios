import Foundation

protocol TokenProvider {
    func getToken() async -> String?
    func getEndpoint() async -> String?
    func setToken(_ token: String) async
    func clearToken() async
}

class KeychainTokenProvider: TokenProvider {
    private let keychainHelper = KeychainHelper.shared
    
    func getToken() async -> String? {
        return keychainHelper.loadToken()
    }
    
    func getEndpoint() async -> String? {
        return keychainHelper.loadEndpoint()
    }
    
    func setToken(_ token: String) async {
        keychainHelper.saveToken(token)
    }
    
    func clearToken() async {
        keychainHelper.clearCredentials()
    }
}
