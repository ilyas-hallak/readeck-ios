//
//  PAuthRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 10.06.25.
//


protocol PAuthRepository {
    func login(endpoint: String, username: String, password: String) async throws -> User
    func logout() async throws
    func getCurrentSettings() async throws -> Settings?
}
