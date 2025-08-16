import Foundation
import Network

class ServerConnectivity: ObservableObject {
    @Published var isServerReachable = false
    
    static let shared = ServerConnectivity()
    
    private init() {}
    
    // Check if the Readeck server endpoint is reachable
    static func isServerReachable() async -> Bool {
        guard let endpoint = KeychainHelper.shared.loadEndpoint(),
              !endpoint.isEmpty,
              let url = URL(string: endpoint + "/api/health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0 // 5 second timeout
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("Server connectivity check failed: \(error)")
        }
        
        return false
    }
    
    // Alternative check using ping-style endpoint
    static func isServerReachableSync() -> Bool {
        guard let endpoint = KeychainHelper.shared.loadEndpoint(),
              !endpoint.isEmpty,
              let url = URL(string: endpoint) else {
            return false
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var isReachable = false
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // Just check if server responds
        request.timeoutInterval = 3.0
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                isReachable = httpResponse.statusCode < 500 // Accept any response that's not server error
            }
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 3.0)
        
        return isReachable
    }
}