//
//  PServerInfoRepository.swift
//  readeck
//
//  Created by Ilyas Hallak

protocol PServerInfoRepository: Sendable {
    func checkServerReachability() async -> Bool
    func getServerInfo(endpoint: String?) async throws -> ServerInfo
}
