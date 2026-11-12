//
//  OAuthRevokeRequestDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 11.11.26.
//

import Foundation

/// Request body for `POST /api/oauth/revoke`. Self-revocation (RFC 7009-style):
/// the same token authenticates the request (Bearer header) and is named again here.
struct OAuthRevokeRequestDto: Codable {
    let token: String
}
