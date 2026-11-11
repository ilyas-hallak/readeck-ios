//
//  NetworkMonitorRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 18.11.25.
//

import Foundation
import Network
@preconcurrency import Combine
import Synchronization

// MARK: - Protocol

protocol PNetworkMonitorRepository: Sendable {
    var isConnected: AnyPublisher<Bool, Never> { get }
    var isForcedOffline: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
    func reportConnectionFailure()
    func reportConnectionSuccess()
    func setForcedOffline(_ isForced: Bool)
}

// MARK: - Implementation

final class NetworkMonitorRepository: PNetworkMonitorRepository {
    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.readeck.networkmonitor")
    private let _isConnectedSubject: CurrentValueSubject<Bool, Never>
    // Written from the NWPathMonitor queue and from the main actor.
    private let connection = Mutex((hasPath: true, hasReal: true))
    private let forcedOfflineSubject = CurrentValueSubject<Bool, Never>(false)

    var isConnected: AnyPublisher<Bool, Never> {
        _isConnectedSubject.eraseToAnyPublisher()
    }

    /// True while the user chose to work offline, e.g. on a network that connects but never answers.
    var isForcedOffline: AnyPublisher<Bool, Never> {
        forcedOfflineSubject.removeDuplicates().eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        // Start as connected. Before the monitor runs, currentPath always reports no
        // connection, which made every launch flip to offline and back. The first path
        // update after startMonitoring() corrects this if the device really is offline.
        _isConnectedSubject = CurrentValueSubject<Bool, Never>(true)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            // More sophisticated check: path must be satisfied AND have actual interfaces
            let hasInterfaces = !path.availableInterfaces.isEmpty
            let isConnected = path.status == .satisfied && hasInterfaces

            self.connection.withLock { $0.hasPath = isConnected }
            self.updateConnectionState()

            // Log network changes with details
            if path.status == .satisfied {
                if hasInterfaces {
                    Logger.network.info("📡 Network path available (interfaces: \(path.availableInterfaces.count))")
                } else {
                    Logger.network.warning("⚠️ Network path satisfied but no interfaces (VPN?)")
                }
            } else {
                Logger.network.warning("📡 Network path unavailable")
            }
        }

        monitor.start(queue: queue)
        Logger.network.debug("Network monitoring started")
    }

    func stopMonitoring() {
        monitor.cancel()
        Logger.network.debug("Network monitoring stopped")
    }

    func reportConnectionFailure() {
        connection.withLock { $0.hasReal = false }
        updateConnectionState()
        Logger.network.warning("⚠️ Real connection failure reported (VPN/unreachable server)")
    }

    func reportConnectionSuccess() {
        connection.withLock { $0.hasReal = true }
        updateConnectionState()
        Logger.network.info("✅ Real connection success reported")
    }

    func setForcedOffline(_ isForced: Bool) {
        forcedOfflineSubject.send(isForced)
        updateConnectionState()
        Logger.network.info("🔌 Forced offline mode: \(isForced)")
    }

    private func updateConnectionState() {
        let state = connection.withLock { $0 }

        // Only connected if BOTH path is available AND real connection works, and the user did not go offline
        let isConnected = state.hasPath && state.hasReal && !forcedOfflineSubject.value

        DispatchQueue.main.async {
            self._isConnectedSubject.send(isConnected)
        }
    }
}
