//
//  ProfileApiClient.swift
//  readeck
//
//  Created by Claude on 19.12.25.
//

import Foundation

protocol PProfileApiClient {
    func getProfile() async throws -> UserProfileDto
}

class ProfileApiClient: PProfileApiClient {
    private let tokenProvider: TokenProvider
    private let logger = Logger.network

    init(tokenProvider: TokenProvider = KeychainTokenProvider()) {
        self.tokenProvider = tokenProvider
    }

    func getProfile() async throws -> UserProfileDto {
        let endpoint = try await resolveEndpoint()
        let url = try buildProfileURL(baseEndpoint: endpoint)
        let request = try await buildProfileRequest(url: url)

        logger.logNetworkRequest(method: "GET", url: url.absoluteString)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for user profile")
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            logger.logNetworkError(method: "GET", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }

        logger.logNetworkRequest(method: "GET", url: url.absoluteString, statusCode: httpResponse.statusCode)

        return try JSONDecoder().decode(UserProfileDto.self, from: data)
    }

    // MARK: - Private Helpers

    private func resolveEndpoint() async throws -> String {
        guard let endpoint = await tokenProvider.getEndpoint() else {
            logger.error("No endpoint available for user profile")
            throw APIError.invalidURL
        }
        return endpoint
    }

    private func buildProfileURL(baseEndpoint: String) throws -> URL {
        guard let url = URL(string: "\(baseEndpoint)/api/profile") else {
            logger.error("Invalid endpoint URL for user profile: \(baseEndpoint)")
            throw APIError.invalidURL
        }
        return url
    }

    private func buildProfileRequest(url: URL) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        // Profile endpoint requires authentication
        guard let token = await tokenProvider.getToken() else {
            logger.error("No authentication token available for user profile")
            throw APIError.serverError(401)
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")

        return request
    }
}
