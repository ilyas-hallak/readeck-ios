import Foundation
import Network

class ServerConnectivity: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    @Published var isServerReachable = false
    
    static let shared = ServerConnectivity()
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                // Network is available, now check server
                Task {
                    let serverReachable = await ServerConnectivity.isServerReachable()
                    DispatchQueue.main.async {
                        let wasReachable = self?.isServerReachable ?? false
                        self?.isServerReachable = serverReachable
                        
                        // Notify when server becomes available
                        if !wasReachable && serverReachable {
                            NotificationCenter.default.post(name: .serverDidBecomeAvailable, object: nil)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.isServerReachable = false
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
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
            // Fallback: try basic endpoint if health endpoint doesn't exist
            return await isBasicEndpointReachable()
        }
        
        return false
    }
    
    private static func isBasicEndpointReachable() async -> Bool {
        guard let endpoint = KeychainHelper.shared.loadEndpoint(),
              !endpoint.isEmpty,
              let url = URL(string: endpoint) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500
            }
        } catch {
            print("Server connectivity check failed: \(error)")
        }
        
        return false
    }
}
