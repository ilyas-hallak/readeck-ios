//
//  NetworkMonitorRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 18.11.25.
//

import Foundation
import Network
import Combine

// MARK: - Protocol

protocol PNetworkMonitorRepository {
    var isConnected: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
    func reportConnectionFailure()
    func reportConnectionSuccess()
}

// MARK: - Implementation

final class NetworkMonitorRepository: PNetworkMonitorRepository {
    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.readeck.networkmonitor")
    private let _isConnectedSubject: CurrentValueSubject<Bool, Never>
    private var hasPathConnection = true
    private var hasRealConnection = true

    var isConnected: AnyPublisher<Bool, Never> {
        _isConnectedSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        // Check current network status synchronously before starting monitor
        let currentPath = monitor.currentPath
        let hasInterfaces = !currentPath.availableInterfaces.isEmpty
        let initialStatus = currentPath.status == .satisfied && hasInterfaces

        _isConnectedSubject = CurrentValueSubject<Bool, Never>(initialStatus)
        hasPathConnection = initialStatus

        Logger.network.info("🌐 Initial network status: \(initialStatus ? "Connected" : "Offline")")
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

            self.hasPathConnection = isConnected
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
        hasRealConnection = false
        updateConnectionState()
        Logger.network.warning("⚠️ Real connection failure reported (VPN/unreachable server)")
    }

    func reportConnectionSuccess() {
        hasRealConnection = true
        updateConnectionState()
        Logger.network.info("✅ Real connection success reported")
    }

    private func updateConnectionState() {
        // Only connected if BOTH path is available AND real connection works
        let isConnected = hasPathConnection && hasRealConnection

        DispatchQueue.main.async {
            self._isConnectedSubject.send(isConnected)
        }
    }
}
