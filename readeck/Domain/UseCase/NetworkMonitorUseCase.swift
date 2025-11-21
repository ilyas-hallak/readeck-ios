//
//  NetworkMonitorUseCase.swift
//  readeck
//
//  Created by Claude on 18.11.25.
//

import Foundation
import Combine

// MARK: - Protocol

protocol PNetworkMonitorUseCase {
    var isConnected: AnyPublisher<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
    func reportConnectionFailure()
    func reportConnectionSuccess()
}

// MARK: - Implementation

final class NetworkMonitorUseCase: PNetworkMonitorUseCase {

    // MARK: - Dependencies

    private let repository: PNetworkMonitorRepository

    // MARK: - Properties

    var isConnected: AnyPublisher<Bool, Never> {
        repository.isConnected
    }

    // MARK: - Initialization

    init(repository: PNetworkMonitorRepository) {
        self.repository = repository
    }

    // MARK: - Public Methods

    func startMonitoring() {
        repository.startMonitoring()
    }

    func stopMonitoring() {
        repository.stopMonitoring()
    }

    func reportConnectionFailure() {
        repository.reportConnectionFailure()
    }

    func reportConnectionSuccess() {
        repository.reportConnectionSuccess()
    }
}
