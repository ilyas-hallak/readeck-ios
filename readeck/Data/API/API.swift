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
    func getBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?) async throws -> BookmarksPageDto
    func getBookmark(id: String) async throws -> BookmarkDetailDto
    func getBookmarkArticle(id: String) async throws -> String
    func createBookmark(createRequest: CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto
    func updateBookmark(id: String, updateRequest: UpdateBookmarkRequestDto) async throws
    func deleteBookmark(id: String) async throws
    func searchBookmarks(search: String) async throws -> BookmarksPageDto
    func getBookmarkLabels() async throws -> [BookmarkLabelDto]
}

class API: PAPI {
    let tokenProvider: TokenProvider
    private var cachedBaseURL: String?
    private let logger = Logger.network
    
    init(tokenProvider: TokenProvider = KeychainTokenProvider()) {
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
    
    private func handleUnauthorizedResponse(_ statusCode: Int) {
        if statusCode == 401 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)
            }
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
            handleUnauthorizedResponse(httpResponse.statusCode)
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
            handleUnauthorizedResponse(httpResponse.statusCode)
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
            handleUnauthorizedResponse(httpResponse.statusCode)
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Als String dekodieren statt als JSON
        guard let string = String(data: data, encoding: .utf8) else {
            throw APIError.invalidResponse
        }
        
        return string
    }
    
    func login(endpoint: String, username: String, password: String) async throws -> UserDto {
        logger.info("Attempting login for user: \(username) at endpoint: \(endpoint)")
        guard let url = URL(string: endpoint + "/api/auth") else { 
            logger.error("Invalid URL for login endpoint: \(endpoint)")
            throw APIError.invalidURL 
        }
        
        let loginRequest = LoginRequestDto(application: "api doc", username: username, password: password)
        let requestData = try JSONEncoder().encode(loginRequest)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        logger.logNetworkRequest(method: "POST", url: url.absoluteString)
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for login request")
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            handleUnauthorizedResponse(httpResponse.statusCode)
            logger.logNetworkError(method: "POST", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }

        logger.logNetworkRequest(method: "POST", url: url.absoluteString, statusCode: httpResponse.statusCode)
        logger.info("Login successful for user: \(username)")
        return try JSONDecoder().decode(UserDto.self, from: data)
    }
    
    func getBookmarks(state: BookmarkState? = nil, limit: Int? = nil, offset: Int? = nil, search: String? = nil, type: [BookmarkType]? = nil, tag: String? = nil) async throws -> BookmarksPageDto {
        logger.debug("Fetching bookmarks with state: \(state?.rawValue ?? "all"), limit: \(limit ?? 0), offset: \(offset ?? 0)")
        var endpoint = "/api/bookmarks"
        var queryItems: [URLQueryItem] = []
        
        // Query-Parameter basierend auf State hinzufügen
        if let state {
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
        
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: "\(offset)"))
        }
        
        if let search {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        // type-Parameter als Array von BookmarkType
        if let type, !type.isEmpty {
            for t in type {
                queryItems.append(URLQueryItem(name: "type", value: t.rawValue))
            }
        }
        
        if let tag {
            queryItems.append(URLQueryItem(name: "labels", value: tag))
        }
        
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            endpoint += "?\(queryString)"
        }
        
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + (endpoint.hasPrefix("/api") ? endpoint : "/api\(endpoint)"))
        
        let (bookmarks, response) = try await makeJSONRequestWithHeaders(
            endpoint: endpoint,
            responseType: [BookmarkDto].self
        )
        
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + (endpoint.hasPrefix("/api") ? endpoint : "/api\(endpoint)"), statusCode: response.statusCode)
        logger.info("Fetched \(bookmarks.count) bookmarks")
        
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
        logger.debug("Fetching bookmark: \(id)")
        let endpoint = "/api/bookmarks/\(id)"
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + endpoint)
        
        let result = try await makeJSONRequest(
            endpoint: endpoint,
            responseType: BookmarkDetailDto.self
        )
        
        logger.info("Successfully fetched bookmark: \(id)")
        return result
    }
    
    // Artikel als String laden statt als JSON
    func getBookmarkArticle(id: String) async throws -> String {
        logger.debug("Fetching article for bookmark: \(id)")
        let endpoint = "/api/bookmarks/\(id)/article"
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + endpoint)
        
        let result = try await makeStringRequest(
            endpoint: endpoint
        )
        
        logger.info("Successfully fetched article for bookmark: \(id)")
        return result
    }
    
    func createBookmark(createRequest: CreateBookmarkRequestDto) async throws -> CreateBookmarkResponseDto {
        logger.info("Creating bookmark for URL: \(createRequest.url)")
        let requestData = try JSONEncoder().encode(createRequest)
        let endpoint = "/api/bookmarks"
        logger.logNetworkRequest(method: "POST", url: await self.baseURL + endpoint)
        
        let result = try await makeJSONRequest(
            endpoint: endpoint,
            method: .POST,
            body: requestData,
            responseType: CreateBookmarkResponseDto.self
        )
        
        logger.info("Successfully created bookmark: \(result.status)")
        return result
    }
    
    func updateBookmark(id: String, updateRequest: UpdateBookmarkRequestDto) async throws {
        logger.info("Updating bookmark: \(id)")
        let requestData = try JSONEncoder().encode(updateRequest)
        
        // Use makeJSONRequest but ignore the response since PATCH returns no body
        let baseURL = await self.baseURL
        let fullEndpoint = "/api/bookmarks/\(id)"
        
        guard let url = URL(string: "\(baseURL)\(fullEndpoint)") else {
            logger.error("Invalid URL: \(baseURL)\(fullEndpoint)")
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
        
        logger.logNetworkRequest(method: "PATCH", url: url.absoluteString)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for PATCH \(url.absoluteString)")
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            handleUnauthorizedResponse(httpResponse.statusCode)
            logger.logNetworkError(method: "PATCH", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        logger.logNetworkRequest(method: "PATCH", url: url.absoluteString, statusCode: httpResponse.statusCode)
        logger.info("Successfully updated bookmark: \(id)")
    }
    
    func deleteBookmark(id: String) async throws {
        logger.info("Deleting bookmark: \(id)")
        
        let baseURL = await self.baseURL
        let fullEndpoint = "/api/bookmarks/\(id)"
        
        guard let url = URL(string: "\(baseURL)\(fullEndpoint)") else {
            logger.error("Invalid URL: \(baseURL)\(fullEndpoint)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = await tokenProvider.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        logger.logNetworkRequest(method: "DELETE", url: url.absoluteString)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for DELETE \(url.absoluteString)")
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            handleUnauthorizedResponse(httpResponse.statusCode)
            logger.logNetworkError(method: "DELETE", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        logger.logNetworkRequest(method: "DELETE", url: url.absoluteString, statusCode: httpResponse.statusCode)
        logger.info("Successfully deleted bookmark: \(id)")
    }
    
    func searchBookmarks(search: String) async throws -> BookmarksPageDto {
        logger.debug("Searching bookmarks with query: \(search)")
        let endpoint = "/api/bookmarks?search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + endpoint)
        
        let (bookmarks, response) = try await makeJSONRequestWithHeaders(
            endpoint: endpoint,
            responseType: [BookmarkDto].self
        )
        
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + endpoint, statusCode: response.statusCode)
        logger.info("Found \(bookmarks.count) bookmarks matching search: \(search)")
        
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
    
    func getBookmarkLabels() async throws -> [BookmarkLabelDto] {
        logger.debug("Fetching bookmark labels")
        let endpoint = "/api/bookmarks/labels"
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + endpoint)
        
        let result = try await makeJSONRequest(
            endpoint: endpoint,
            responseType: [BookmarkLabelDto].self
        )
        
        logger.info("Successfully fetched \(result.count) bookmark labels")
        return result
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
