//
//  OAuthFlowCoordinator.swift
//  readeck
//
//  Created by Ilyas Hallak on 16.12.25.
//

import Foundation

/// Coordinates the complete OAuth 2.0 flow from start to finish
@MainActor
final class OAuthFlowCoordinator {
    private let manager: OAuthManager
    private let session: OAuthSession
    private let logger = Logger.network

    // Temporary storage for OAuth flow state
    private var currentClient: OAuthClient?
    private var currentVerifier: String?
    private var currentState: String?
    private var currentEndpoint: String?

    init(manager: OAuthManager) {
        self.manager = manager
        self.session = OAuthSession()
    }

    /// Executes the complete OAuth flow
    /// - Parameter endpoint: Server endpoint URL
    /// - Returns: (OAuth access token, Client ID)
    func executeOAuthFlow(endpoint: String) async throws -> (OAuthToken, String) {
        logger.info("🔐 Starting OAuth flow for endpoint: \(endpoint)")

        // Phase 1: Register client and generate PKCE
        logger.info("Phase 1: Registering OAuth client...")
        let (client, verifier, challenge, state) = try await manager.startOAuthFlow(endpoint: endpoint)

        // Store state for later use
        self.currentClient = client
        self.currentVerifier = verifier
        self.currentState = state
        self.currentEndpoint = endpoint

        logger.info("✅ Client registered: \(client.clientId)")
        logger.info("🔑 PKCE challenge generated")

        // Phase 2: Build authorization URL
        guard let authURL = manager.buildAuthorizationURL(
            endpoint: endpoint,
            clientId: client.clientId,
            codeChallenge: challenge,
            state: state
        ) else {
            logger.error("Failed to build authorization URL")
            throw OAuthError.invalidCallback
        }

        logger.info("🌐 Authorization URL: \(authURL.absoluteString)")

        // Phase 3: Open browser for user authentication
        logger.info("Phase 2: Opening browser for user authentication...")
        let callbackURL = try await withCheckedThrowingContinuation { continuation in
            session.start(
                url: authURL,
                callbackURLScheme: "readeck"
            ) { result in
                continuation.resume(with: result)
            }
        }

        logger.info("✅ Received callback: \(callbackURL.absoluteString)")

        // Phase 4: Parse callback URL
        guard let (code, receivedState) = OAuthManager.parseCallbackURL(callbackURL) else {
            logger.error("Failed to parse callback URL")
            throw OAuthError.invalidCallback
        }

        logger.info("📋 Authorization code received")
        logger.info("🔐 State verification...")

        // Phase 5: Exchange code for token
        guard let savedState = currentState,
              let savedVerifier = currentVerifier,
              let savedClient = currentClient else {
            logger.error("OAuth flow state was lost")
            throw OAuthError.invalidCallback
        }

        logger.info("Phase 3: Exchanging authorization code for access token...")
        let token = try await manager.completeOAuthFlow(
            endpoint: endpoint,
            clientId: savedClient.clientId,
            code: code,
            codeVerifier: savedVerifier,
            receivedState: receivedState,
            expectedState: savedState
        )

        logger.info("✅ Access token obtained successfully")
        logger.info("🎉 OAuth flow completed!")

        // Save client ID before cleanup
        let clientId = savedClient.clientId

        // Clean up state
        cleanup()

        return (token, clientId)
    }

    /// Cancels the ongoing OAuth flow
    func cancelFlow() {
        logger.info("❌ Cancelling OAuth flow")
        session.cancel()
        cleanup()
    }

    private func cleanup() {
        currentClient = nil
        currentVerifier = nil
        currentState = nil
        currentEndpoint = nil
    }
}
