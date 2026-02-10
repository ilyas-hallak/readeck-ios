//
//  OAuthClient.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// OAuth client model for the domain layer
struct OAuthClient {
    let clientId: String
    let clientSecret: String?
    let clientName: String
    let redirectUris: [String]
    let grantTypes: [String]
}

extension OAuthClient {
    init(from dto: OAuthClientResponseDto) {
        self.clientId = dto.clientId
        self.clientSecret = dto.clientSecret
        self.clientName = dto.clientName
        self.redirectUris = dto.redirectUris
        self.grantTypes = dto.grantTypes
    }
}
