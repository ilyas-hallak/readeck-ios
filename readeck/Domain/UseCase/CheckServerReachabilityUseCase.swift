//
//  CheckServerReachabilityUseCase.swift
//  readeck
//
//  Created by Claude Code

import Foundation

protocol PCheckServerReachabilityUseCase {
    func execute() async -> Bool
    func getServerInfo() async throws -> ServerInfo
}

class CheckServerReachabilityUseCase: PCheckServerReachabilityUseCase {
    private let repository: PServerInfoRepository

    init(repository: PServerInfoRepository) {
        self.repository = repository
    }

    func execute() async -> Bool {
        return await repository.checkServerReachability()
    }

    func getServerInfo() async throws -> ServerInfo {
        return try await repository.getServerInfo()
    }
}
