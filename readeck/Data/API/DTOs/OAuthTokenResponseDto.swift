//
//  OAuthTokenResponseDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Response DTO from OAuth token exchange
struct OAuthTokenResponseDto: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String?
    let expiresIn: Int?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
