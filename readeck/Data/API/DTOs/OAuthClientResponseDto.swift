//
//  OAuthClientResponseDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Response DTO from OAuth client registration
struct OAuthClientResponseDto: Codable {
    let clientId: String
    let clientSecret: String?
    let clientName: String
    let redirectUris: [String]
    let grantTypes: [String]

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
        case clientName = "client_name"
        case redirectUris = "redirect_uris"
        case grantTypes = "grant_types"
    }
}
