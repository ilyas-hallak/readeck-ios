//
//  OAuthRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation

class OAuthRepository: POAuthRepository {
    private let api: PAPI
    private let logger = Logger.network

    init(api: PAPI) {
        self.api = api
    }

    func registerClient(endpoint: String, clientName: String, redirectUri: String) async throws -> OAuthClient {
        logger.info("Registering OAuth client: \(clientName)")

        // Get app version for software_version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        // Create unique software_id (could be stored in UserDefaults for consistency)
        let softwareId = UUID().uuidString

        let request = OAuthClientCreateDto(
            clientName: clientName,
            clientUri: "https://github.com/yourusername/readeck-ios", // TODO: Update with actual URL
            softwareId: softwareId,
            softwareVersion: appVersion,
            redirectUris: [redirectUri],
            grantTypes: ["authorization_code"]
        )

        let response = try await api.registerOAuthClient(endpoint: endpoint, request: request)
        return OAuthClient(from: response)
    }

    func exchangeToken(
        endpoint: String,
        clientId: String,
        code: String,
        codeVerifier: String,
        redirectUri: String
    ) async throws -> OAuthToken {
        logger.info("Exchanging authorization code for access token")

        let request = OAuthTokenRequestDto(
            grantType: "authorization_code",
            clientId: clientId,
            code: code,
            codeVerifier: codeVerifier,
            redirectUri: redirectUri
        )

        let response = try await api.exchangeOAuthToken(endpoint: endpoint, request: request)
        return OAuthToken(from: response)
    }
}
