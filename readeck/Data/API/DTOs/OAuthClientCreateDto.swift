//
//  OAuthClientCreateDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Request DTO for creating an OAuth client
/// According to RFC 7591 (OAuth 2.0 Dynamic Client Registration)
struct OAuthClientCreateDto: Codable {
    let clientName: String
    let clientUri: String
    let softwareId: String
    let softwareVersion: String
    let redirectUris: [String]
    let grantTypes: [String]

    enum CodingKeys: String, CodingKey {
        case clientName = "client_name"
        case clientUri = "client_uri"
        case softwareId = "software_id"
        case softwareVersion = "software_version"
        case redirectUris = "redirect_uris"
        case grantTypes = "grant_types"
    }
}
