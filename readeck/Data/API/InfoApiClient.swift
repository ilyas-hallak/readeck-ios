//
//  InfoApiClient.swift
//  readeck
//
//  Created by Ilyas Hallak

import Foundation

protocol PInfoApiClient {
    func getServerInfo(endpoint: String?) async throws -> ServerInfoDto
}

class InfoApiClient: PInfoApiClient {
    private let tokenProvider: TokenProvider
    private let logger = Logger.network

    init(tokenProvider: TokenProvider = KeychainTokenProvider()) {
        self.tokenProvider = tokenProvider
    }

    func getServerInfo(endpoint: String? = nil) async throws -> ServerInfoDto {
        let baseEndpoint = try await resolveEndpoint(endpoint)
        let url = try buildInfoURL(baseEndpoint: baseEndpoint)
        var request = try await buildInfoRequest(url: url, useStoredEndpoint: endpoint == nil)

        HTTPHeadersHelper.shared.applyCustomHeaders(to: &request)

        logger.logNetworkRequest(method: "GET", url: url.absoluteString)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for server info")
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            logger.logNetworkError(method: "GET", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }

        logger.logNetworkRequest(method: "GET", url: url.absoluteString, statusCode: httpResponse.statusCode)

        return try JSONDecoder().decode(ServerInfoDto.self, from: data)
    }

    // MARK: - Private Helpers

    private func resolveEndpoint(_ providedEndpoint: String?) async throws -> String {
        if let providedEndpoint = providedEndpoint {
            return providedEndpoint
        } else if let storedEndpoint = await tokenProvider.getEndpoint() {
            return storedEndpoint
        } else {
            logger.error("No endpoint available for server info")
            throw APIError.invalidURL
        }
    }

    private func buildInfoURL(baseEndpoint: String) throws -> URL {
        guard let url = URL(string: "\(baseEndpoint)/api/info") else {
            logger.error("Invalid endpoint URL for server info: \(baseEndpoint)")
            throw APIError.invalidURL
        }
        return url
    }

    private func buildInfoRequest(url: URL, useStoredEndpoint: Bool) async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 5.0

        // Only add token if using stored endpoint (not custom endpoint)
        if useStoredEndpoint, let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }

        return request
    }
}
