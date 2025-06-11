//
//  API.swift
//  readeck
//
//  Created by Ilyas Hallak on 10.06.25.
//

import Foundation

protocol PAPI {
    var tokenProvider: TokenProvider { get }
    func login(username: String, password: String) async throws -> UserDto
    func getBookmarks(state: BookmarkState?) async throws -> [BookmarkDto]
    func getBookmark(id: String) async throws -> BookmarkDetailDto
    func getBookmarkArticle(id: String) async throws -> String
}

class API: PAPI {
    let tokenProvider: TokenProvider
    private var cachedBaseURL: String?
    
    init(tokenProvider: TokenProvider = CoreDataTokenProvider()) {
        self.tokenProvider = tokenProvider
    }
    
    private var baseURL: String {
        get async {
            if let cached = cachedBaseURL {
                return cached
            }
            let url = await tokenProvider.getEndpoint()
            cachedBaseURL = url
            return url
        }
    }
    
    // Separate Methode für JSON-Requests
    private func makeJSONRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        let baseURL = await self.baseURL
        let fullEndpoint = endpoint.hasPrefix("/api") ? endpoint : "/api\(endpoint)"
        
        guard let url = URL(string: "\(baseURL)\(fullEndpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("Server Error: \(httpResponse.statusCode) - \(String(data: data, encoding: .utf8) ?? "No response body")")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // Separate Methode für String-Requests (HTML/Text)
    private func makeStringRequest(
        endpoint: String,
        method: HTTPMethod = .GET
    ) async throws -> String {
        let baseURL = await self.baseURL
        let fullEndpoint = endpoint.hasPrefix("/api") ? endpoint : "/api\(endpoint)"
        
        guard let url = URL(string: "\(baseURL)\(fullEndpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Als String dekodieren statt als JSON
        guard let string = String(data: data, encoding: .utf8) else {
            throw APIError.invalidResponse
        }
        
        return string
    }
    
    func login(username: String, password: String) async throws -> UserDto {
        let loginRequest = LoginRequestDto(application: "api doc", username: username, password: password)
        let requestData = try JSONEncoder().encode(loginRequest)
        
        let userDto = try await makeJSONRequest(
            endpoint: "/api/auth",
            method: .POST,
            body: requestData,
            responseType: UserDto.self
        )
        
        // Token automatisch speichern nach erfolgreichem Login
        await tokenProvider.setToken(userDto.token)
        
        return userDto
    }
    
    func getBookmarks(state: BookmarkState? = nil) async throws -> [BookmarkDto] {
        var endpoint = "/api/bookmarks"
        
        // Query-Parameter basierend auf State hinzufügen
        if let state = state {
            switch state {
            case .unread:
                endpoint += "?is_archived=false&is_marked=false"
            case .favorite:
                endpoint += "?is_marked=true"
            case .archived:
                endpoint += "?is_archived=true"
            }
        }
        
        return try await makeJSONRequest(
            endpoint: endpoint,
            responseType: [BookmarkDto].self
        )
    }
    
    func getBookmark(id: String) async throws -> BookmarkDetailDto {
        return try await makeJSONRequest(
            endpoint: "/api/bookmarks/\(id)",
            responseType: BookmarkDetailDto.self
        )
    }
    
    // Artikel als String laden statt als JSON
    func getBookmarkArticle(id: String) async throws -> String {
        return try await makeStringRequest(
            endpoint: "/api/bookmarks/\(id)/article"
        )
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
}
