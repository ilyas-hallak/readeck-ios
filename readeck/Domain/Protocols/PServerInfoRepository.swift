//
//  PServerInfoRepository.swift
//  readeck
//
//  Created by Claude Code

protocol PServerInfoRepository {
    func checkServerReachability() async -> Bool
    func getServerInfo() async throws -> ServerInfo
}
