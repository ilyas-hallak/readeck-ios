//
//  InfoApiClient.swift
//  readeck
//
//  Created by Claude Code

import Foundation

protocol PInfoApiClient {
    func getServerInfo() async throws -> ServerInfoDto
}

class InfoApiClient: PInfoApiClient {
    private let tokenProvider: TokenProvider
    private let logger = Logger.network

    init(tokenProvider: TokenProvider = KeychainTokenProvider()) {
        self.tokenProvider = tokenProvider
    }

    func getServerInfo() async throws -> ServerInfoDto {
        guard let endpoint = await tokenProvider.getEndpoint(),
              let url = URL(string: "\(endpoint)/api/info") else {
            logger.error("Invalid endpoint URL for server info")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 5.0

        if let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }

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
}
