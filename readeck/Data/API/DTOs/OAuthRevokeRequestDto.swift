//
//  OAuthRevokeRequestDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 11.11.26.
//

import Foundation

/// Request body for `POST /api/oauth/revoke`.
struct OAuthRevokeRequestDto: Codable {
    let token: String
}
