//
//  POAuthRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

protocol POAuthRepository {
    /// Registers an OAuth client with the server
    /// - Parameters:
    ///   - endpoint: Server endpoint URL
    ///   - clientName: Name of the client application
    ///   - redirectUri: Redirect URI for OAuth callback
    /// - Returns: Registered OAuth client
    func registerClient(endpoint: String, clientName: String, redirectUri: String) async throws -> OAuthClient

    /// Exchanges an authorization code for an access token
    /// - Parameters:
    ///   - endpoint: Server endpoint URL
    ///   - clientId: OAuth client ID
    ///   - code: Authorization code from OAuth callback
    ///   - codeVerifier: PKCE code verifier
    ///   - redirectUri: Redirect URI (must match the one used in authorization request)
    /// - Returns: OAuth access token
    func exchangeToken(endpoint: String, clientId: String, code: String, codeVerifier: String, redirectUri: String) async throws -> OAuthToken
}
