//
//  OAuthManager.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

/// Orchestrates the OAuth 2.0 Authorization Code flow with PKCE
class OAuthManager {
    private let repository: POAuthRepository
    private let logger = Logger.network

    // OAuth configuration
    static let redirectUri = "readeck://oauth-callback"
    static let clientName = "Readeck iOS"
    static let scopes = "bookmarks:read bookmarks:write profile:read"

    init(repository: POAuthRepository) {
        self.repository = repository
    }

    /// Builds the authorization URL for OAuth flow
    /// - Parameters:
    ///   - endpoint: Server endpoint URL
    ///   - clientId: OAuth client ID
    ///   - codeChallenge: PKCE code challenge
    ///   - state: CSRF protection state
    /// - Returns: Authorization URL
    func buildAuthorizationURL(
        endpoint: String,
        clientId: String,
        codeChallenge: String,
        state: String
    ) -> URL? {
        var components = URLComponents(string: "\(endpoint)/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: Self.redirectUri),
            URLQueryItem(name: "scope", value: Self.scopes),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "response_type", value: "code")
        ]
        return components?.url
    }

    /// Starts the OAuth flow by registering a client
    /// - Parameters:
    ///   - endpoint: Server endpoint URL
    /// - Returns: Tuple containing (client, PKCE verifier, PKCE challenge, state)
    func startOAuthFlow(endpoint: String) async throws -> (client: OAuthClient, verifier: String, challenge: String, state: String) {
        logger.info("Starting OAuth flow for endpoint: \(endpoint)")

        // Generate PKCE
        let (verifier, challenge) = PKCEGenerator.generate()

        // Generate CSRF state
        let state = UUID().uuidString

        // Register OAuth client
        let client = try await repository.registerClient(
            endpoint: endpoint,
            clientName: Self.clientName,
            redirectUri: Self.redirectUri
        )

        logger.info("OAuth client registered with ID: \(client.clientId)")

        return (client, verifier, challenge, state)
    }

    /// Completes the OAuth flow by exchanging the authorization code for a token
    /// - Parameters:
    ///   - endpoint: Server endpoint URL
    ///   - clientId: OAuth client ID
    ///   - code: Authorization code from redirect
    ///   - codeVerifier: PKCE code verifier
    ///   - receivedState: State from redirect (for CSRF verification)
    ///   - expectedState: Expected state value
    /// - Returns: OAuth access token
    func completeOAuthFlow(
        endpoint: String,
        clientId: String,
        code: String,
        codeVerifier: String,
        receivedState: String,
        expectedState: String
    ) async throws -> OAuthToken {
        logger.info("Completing OAuth flow")

        // Verify state to prevent CSRF attacks
        guard receivedState == expectedState else {
            logger.error("OAuth state mismatch - possible CSRF attack")
            throw OAuthError.stateMismatch
        }

        // Exchange code for token
        let token = try await repository.exchangeToken(
            endpoint: endpoint,
            clientId: clientId,
            code: code,
            codeVerifier: codeVerifier,
            redirectUri: Self.redirectUri
        )

        logger.info("Successfully obtained OAuth access token")
        return token
    }

    /// Parses the OAuth callback URL to extract code and state
    /// - Parameter url: Callback URL
    /// - Returns: Tuple containing (code, state) if successful, nil otherwise
    static func parseCallbackURL(_ url: URL) -> (code: String, state: String)? {
        guard url.scheme == "readeck",
              url.host == "oauth-callback",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }

        let code = queryItems.first(where: { $0.name == "code" })?.value
        let state = queryItems.first(where: { $0.name == "state" })?.value

        guard let code = code, let state = state else {
            return nil
        }

        return (code, state)
    }
}

// MARK: - OAuth Errors

enum OAuthError: LocalizedError {
    case stateMismatch
    case invalidCallback
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .stateMismatch:
            return "OAuth state verification failed (possible CSRF attack)"
        case .invalidCallback:
            return "Invalid OAuth callback URL"
        case .userCancelled:
            return "OAuth authorization was cancelled by user"
        }
    }
}
