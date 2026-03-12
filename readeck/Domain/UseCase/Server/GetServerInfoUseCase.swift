//
//  GetServerInfoUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak

import Foundation

protocol PGetServerInfoUseCase {
    func execute(endpoint: String?) async throws -> ServerInfo
}

class GetServerInfoUseCase: PGetServerInfoUseCase {
    private let repository: PServerInfoRepository

    init(repository: PServerInfoRepository) {
        self.repository = repository
    }

    func execute(endpoint: String? = nil) async throws -> ServerInfo {
        return try await repository.getServerInfo(endpoint: endpoint)
    }
}
