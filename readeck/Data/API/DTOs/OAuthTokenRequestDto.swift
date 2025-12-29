//
//  OAuthTokenRequestDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Request DTO for exchanging authorization code for access token or refreshing tokens
struct OAuthTokenRequestDto: Codable {
    let grantType: String
    let clientId: String
    let code: String?
    let codeVerifier: String?
    let redirectUri: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case clientId = "client_id"
        case code
        case codeVerifier = "code_verifier"
        case redirectUri = "redirect_uri"
        case refreshToken = "refresh_token"
    }

    // Convenience initializer for authorization code exchange
    init(clientId: String, code: String, codeVerifier: String, redirectUri: String) {
        self.grantType = "authorization_code"
        self.clientId = clientId
        self.code = code
        self.codeVerifier = codeVerifier
        self.redirectUri = redirectUri
        self.refreshToken = nil
    }

    // Convenience initializer for token refresh
    init(clientId: String, refreshToken: String) {
        self.grantType = "refresh_token"
        self.clientId = clientId
        self.code = nil
        self.codeVerifier = nil
        self.redirectUri = nil
        self.refreshToken = refreshToken
    }
}
