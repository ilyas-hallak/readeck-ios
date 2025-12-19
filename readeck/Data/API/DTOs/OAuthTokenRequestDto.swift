//
//  OAuthTokenRequestDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Request DTO for exchanging authorization code for access token
struct OAuthTokenRequestDto: Codable {
    let grantType: String
    let clientId: String
    let code: String
    let codeVerifier: String
    let redirectUri: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case clientId = "client_id"
        case code
        case codeVerifier = "code_verifier"
        case redirectUri = "redirect_uri"
    }
}
