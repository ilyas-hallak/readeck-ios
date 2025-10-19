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
        let useCase = DefaultUseCaseFactory.shared.makeCheckServerReachabilityUseCase()
        return await useCase.execute()
    }
}
