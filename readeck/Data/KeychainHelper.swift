import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    private static let accessGroup = "8J69P655GN.de.ilyashallak.readeck"
    
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        saveString(token, forKey: "readeck_token")
    }
    
    func loadToken() -> String? {
        loadString(forKey: "readeck_token")
    }
    
    @discardableResult
    func saveEndpoint(_ endpoint: String) -> Bool {
        saveString(endpoint, forKey: "readeck_endpoint")
    }
    
    func loadEndpoint() -> String? {
        loadString(forKey: "readeck_endpoint")
    }
    
    // MARK: - Private generic helpers
    @discardableResult
    private func saveString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessGroup as String: KeychainHelper.accessGroup
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func loadString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: KeychainHelper.accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
} 
