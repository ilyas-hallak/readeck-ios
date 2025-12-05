//
//  PServerInfoRepository.swift
//  readeck
//
//  Created by Ilyas Hallak

protocol PServerInfoRepository {
    func checkServerReachability() async -> Bool
    func getServerInfo() async throws -> ServerInfo
}
