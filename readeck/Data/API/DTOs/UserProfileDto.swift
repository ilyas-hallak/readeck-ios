//
//  UserProfileDto.swift
//  readeck
//
//  Created by Claude on 19.12.25.
//

import Foundation

/// User profile response DTO from /api/profile
struct UserProfileDto: Codable {
    let user: UserDto
    let provider: ProviderDto

    struct UserDto: Codable {
        let username: String
        let email: String?
        let created: String?
        let updated: String?
    }

    struct ProviderDto: Codable {
        let id: String
        let name: String
        let application: String?
        let roles: [String]?
        let permissions: [String]?
    }
}
