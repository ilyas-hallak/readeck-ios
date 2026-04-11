//
//  CheckServerReachabilityUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak

import Foundation

protocol PCheckServerReachabilityUseCase {
    func execute() async -> Bool
    func getServerInfo() async throws -> ServerInfo
}

final class CheckServerReachabilityUseCase: PCheckServerReachabilityUseCase {
    private let repository: PServerInfoRepository

    init(repository: PServerInfoRepository) {
        self.repository = repository
    }

    func execute() async -> Bool {
        await repository.checkServerReachability()
    }

    func getServerInfo() async throws -> ServerInfo {
        try await repository.getServerInfo(endpoint: nil)
    }
}
