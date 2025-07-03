//
//  API.swift
//  readeck
//
//  Created by Ilyas Hallak on 10.06.25.
//

import Foundation

protocol PAPI {
    var tokenProvider: TokenProvider { get }
    func login(endpoint: String, username: String, password: String) async throws -> UserDto
    func getBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?) async throws -> BookmarksPageDto
    func getBookmark(id: String) async throws -> BookmarkDetailDto
    func getBookmarkArticle(id: String) async throws -> String
    func createBookmark(createRequest: CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto
    func updateBookmark(id: String, updateRequest: UpdateBookmarkRequestDto) async throws
    func deleteBookmark(id: String) async throws
    func searchBookmarks(search: String) async throws -> BookmarksPageDto
}

class API: PAPI {
    let tokenProvider: TokenProvider
    private var cachedBaseURL: String?
    
    init(tokenProvider: TokenProvider = CoreDataTokenProvider()) {
        self.tokenProvider = tokenProvider
    }
    
    private var baseURL: String {
        get async {
            if let cached = cachedBaseURL, cached.isEmpty == false {
                return cached
            }
            guard let url = await tokenProvider.getEndpoint() else {
                return ""
            }
            cachedBaseURL = url
            return url
        }
    }
        
    private func makeJSONRequestWithHeaders<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> (T, HTTPURLResponse) {
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
        
        let decoded = try JSONDecoder().decode(T.self, from: data)
        return (decoded, httpResponse)
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
    
    func login(endpoint: String, username: String, password: String) async throws -> UserDto {
        let loginRequest = LoginRequestDto(application: "api doc", username: username, password: password)
        let requestData = try JSONEncoder().encode(loginRequest)
        guard let url = URL(string: endpoint + "/api/auth") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        let userDto = try JSONDecoder().decode(UserDto.self, from: data)
        // Token NICHT automatisch speichern, da Settings noch nicht existieren
        return userDto
    }
    
    // Angepasste getBookmarks-Methode mit Header-Auslesen
    func getBookmarks(state: BookmarkState? = nil, limit: Int? = nil, offset: Int? = nil, search: String? = nil, type: [BookmarkType]? = nil) async throws -> BookmarksPageDto {
        var endpoint = "/api/bookmarks"
        var queryItems: [URLQueryItem] = []
        
        // Query-Parameter basierend auf State hinzufügen
        if let state = state {
            switch state {
            case .unread:
                queryItems.append(URLQueryItem(name: "is_archived", value: "false"))
                queryItems.append(URLQueryItem(name: "is_marked", value: "false"))
            case .favorite:
                queryItems.append(URLQueryItem(name: "is_marked", value: "true"))
            case .archived:
                queryItems.append(URLQueryItem(name: "is_archived", value: "true"))
            case .all:
                break
            }
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        }
        
        if let search = search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        // type-Parameter als Array von BookmarkType
        if let type = type, !type.isEmpty {
            for t in type {
                queryItems.append(URLQueryItem(name: "type", value: t.rawValue))
            }
        }
        
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        let (bookmarks, response) = try await makeJSONRequestWithHeaders(
            endpoint: endpoint,
            responseType: [BookmarkDto].self
        )
        
        // Header auslesen
        let currentPage = response.value(forHTTPHeaderField: "Current-Page").flatMap { Int($0) }
        let totalCount = response.value(forHTTPHeaderField: "Total-Count").flatMap { Int($0) }
        let totalPages = response.value(forHTTPHeaderField: "Total-Pages").flatMap { Int($0) }
        let linksHeader = response.value(forHTTPHeaderField: "Link")
        let links = linksHeader?.components(separatedBy: ",")
        
        return BookmarksPageDto(
            bookmarks: bookmarks,
            currentPage: currentPage,
            totalCount: totalCount,
            totalPages: totalPages,
            links: links
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
    
    func createBookmark(createRequest: CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto {
        let requestData = try JSONEncoder().encode(createRequest)
        
        return try await makeJSONRequest(
            endpoint: "/api/bookmarks",
            method: .POST,
            body: requestData,
            responseType: CreateBookmarkResponseDto.self
        )
    }
    
    func updateBookmark(id: String, updateRequest: UpdateBookmarkRequestDto) async throws {
        let requestData = try JSONEncoder().encode(updateRequest)
        
        // PATCH Request ohne Response-Body erwarten
        let baseURL = await self.baseURL
        let fullEndpoint = "/api/bookmarks/\(id)"
        
        guard let url = URL(string: "\(baseURL)\(fullEndpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = requestData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("Server Error: \(httpResponse.statusCode)")
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func deleteBookmark(id: String) async throws {
        // DELETE Request ohne Response-Body erwarten
        let baseURL = await self.baseURL
        let fullEndpoint = "/api/bookmarks/\(id)"
        
        guard let url = URL(string: "\(baseURL)\(fullEndpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("Server Error: \(httpResponse.statusCode)")
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func searchBookmarks(search: String) async throws -> BookmarksPageDto {
        let endpoint = "/api/bookmarks?search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        let (bookmarks, response) = try await makeJSONRequestWithHeaders(
            endpoint: endpoint,
            responseType: [BookmarkDto].self
        )
        let currentPage = response.value(forHTTPHeaderField: "Current-Page").flatMap { Int($0) }
        let totalCount = response.value(forHTTPHeaderField: "Total-Count").flatMap { Int($0) }
        let totalPages = response.value(forHTTPHeaderField: "Total-Pages").flatMap { Int($0) }
        let linksHeader = response.value(forHTTPHeaderField: "Link")
        let links = linksHeader?.components(separatedBy: ",")
        return BookmarksPageDto(
            bookmarks: bookmarks,
            currentPage: currentPage,
            totalCount: totalCount,
            totalPages: totalPages,
            links: links
        )
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
}
