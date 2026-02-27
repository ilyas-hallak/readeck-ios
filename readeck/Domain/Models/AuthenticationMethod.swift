//
//  AuthenticationMethod.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Enum to distinguish between different authentication methods
enum AuthenticationMethod: String, Codable {
    case apiToken = "api_token"
    case oauth = "oauth"
}
