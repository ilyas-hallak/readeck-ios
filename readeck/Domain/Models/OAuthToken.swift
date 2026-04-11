//
//  OAuthToken.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// OAuth access token model for the domain layer
struct OAuthToken: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String?
    let expiresIn: Int?
    let refreshToken: String?
    let createdAt: Date

    var isExpired: Bool {
        guard let expiresIn else { return false }
        let expiryDate = createdAt.addingTimeInterval(TimeInterval(expiresIn))
        return Date() > expiryDate
    }
}

extension OAuthToken {
    init(from dto: OAuthTokenResponseDto) {
        self.accessToken = dto.accessToken
        self.tokenType = dto.tokenType
        self.scope = dto.scope
        self.expiresIn = dto.expiresIn
        self.refreshToken = dto.refreshToken
        self.createdAt = Date()
    }
}
