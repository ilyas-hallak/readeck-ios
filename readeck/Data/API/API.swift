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
    func getBookmarkAnnotations(bookmarkId: String) async throws -> [AnnotationDto]
    func createAnnotation(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> AnnotationDto
    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws

    // OAuth methods
    func registerOAuthClient(endpoint: String, request: OAuthClientCreateDto) async throws -> OAuthClientResponseDto
    func exchangeOAuthToken(endpoint: String, request: OAuthTokenRequestDto) async throws -> OAuthTokenResponseDto
}

class API: PAPI {
    let tokenProvider: TokenProvider
    private let logger = Logger.network

    init(tokenProvider: TokenProvider = KeychainTokenProvider()) {
        self.tokenProvider = tokenProvider
    }

    private var baseURL: String {
        get async {
            // Always get endpoint from tokenProvider (it has its own cache)
            guard let url = await tokenProvider.getEndpoint() else {
                return ""
            }
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
            // Try to extract error message from response body
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverErrorWithMessage(statusCode: httpResponse.statusCode, message: errorResponse.message)
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private struct APIErrorResponse: Codable {
        let status: Int
        let message: String
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
            logger.error("Invalid HTTP response for \(endpoint)")
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            logger.error("Server error for \(endpoint): HTTP \(httpResponse.statusCode)")
            logger.error("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            handleUnauthorizedResponse(httpResponse.statusCode)
            throw APIError.serverError(httpResponse.statusCode)
        }

        // Als String dekodieren statt als JSON
        guard let string = String(data: data, encoding: .utf8) else {
            logger.error("Unable to decode response as UTF-8 string for \(endpoint)")
            logger.error("Data size: \(data.count) bytes")
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
            // URL-encode label with quotes for proper API handling
            let encodedTag = "\"\(tag)\""
            queryItems.append(URLQueryItem(name: "labels", value: encodedTag))
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

    func getBookmarkAnnotations(bookmarkId: String) async throws -> [AnnotationDto] {
        logger.debug("Fetching annotations for bookmark: \(bookmarkId)")
        let endpoint = "/api/bookmarks/\(bookmarkId)/annotations"
        logger.logNetworkRequest(method: "GET", url: await self.baseURL + endpoint)

        let result = try await makeJSONRequest(
            endpoint: endpoint,
            responseType: [AnnotationDto].self
        )

        logger.info("Successfully fetched \(result.count) annotations for bookmark: \(bookmarkId)")
        return result
    }

    func createAnnotation(bookmarkId: String, color: String, startOffset: Int, endOffset: Int, startSelector: String, endSelector: String) async throws -> AnnotationDto {
        logger.debug("Creating annotation for bookmark: \(bookmarkId)")
        let endpoint = "/api/bookmarks/\(bookmarkId)/annotations"
        logger.logNetworkRequest(method: "POST", url: await self.baseURL + endpoint)

        let bodyDict: [String: Any] = [
            "color": color,
            "start_offset": startOffset,
            "end_offset": endOffset,
            "start_selector": startSelector,
            "end_selector": endSelector
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: bodyDict, options: [])

        let result = try await makeJSONRequest(
            endpoint: endpoint,
            method: .POST,
            body: bodyData,
            responseType: AnnotationDto.self
        )

        logger.info("Successfully created annotation for bookmark: \(bookmarkId)")
        return result
    }

    func deleteAnnotation(bookmarkId: String, annotationId: String) async throws {
        logger.info("Deleting annotation: \(annotationId) from bookmark: \(bookmarkId)")

        let baseURL = await self.baseURL
        let fullEndpoint = "/api/bookmarks/\(bookmarkId)/annotations/\(annotationId)"

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
        logger.info("Successfully deleted annotation: \(annotationId)")
    }

    // MARK: - OAuth Methods

    func registerOAuthClient(endpoint: String, request: OAuthClientCreateDto) async throws -> OAuthClientResponseDto {
        logger.info("Registering OAuth client for endpoint: \(endpoint)")
        guard let url = URL(string: "\(endpoint)/api/oauth/client") else {
            logger.error("Invalid URL for OAuth client registration: \(endpoint)")
            throw APIError.invalidURL
        }

        let requestData = try JSONEncoder().encode(request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = requestData

        logger.logNetworkRequest(method: "POST", url: url.absoluteString)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for OAuth client registration")
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            logger.logNetworkError(method: "POST", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }

        logger.logNetworkRequest(method: "POST", url: url.absoluteString, statusCode: httpResponse.statusCode)
        let clientResponse = try JSONDecoder().decode(OAuthClientResponseDto.self, from: data)
        logger.info("Successfully registered OAuth client: \(clientResponse.clientId)")
        return clientResponse
    }

    func exchangeOAuthToken(endpoint: String, request: OAuthTokenRequestDto) async throws -> OAuthTokenResponseDto {
        let isRefresh = request.grantType == "refresh_token"
        logger.info(isRefresh ? "Refreshing OAuth access token" : "Exchanging OAuth authorization code for access token")

        guard let url = URL(string: "\(endpoint)/api/oauth/token") else {
            logger.error("Invalid URL for OAuth token exchange: \(endpoint)")
            throw APIError.invalidURL
        }

        // Build form data based on grant type
        var formData: [String: String] = [
            "grant_type": request.grantType,
            "client_id": request.clientId
        ]

        // Add fields based on grant type
        if isRefresh {
            if let refreshToken = request.refreshToken {
                formData["refresh_token"] = refreshToken
            }
        } else {
            if let code = request.code {
                formData["code"] = code
            }
            if let codeVerifier = request.codeVerifier {
                formData["code_verifier"] = codeVerifier
            }
            if let redirectUri = request.redirectUri {
                formData["redirect_uri"] = redirectUri
            }
        }

        let formBody = formData.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = formBody.data(using: .utf8)

        logger.logNetworkRequest(method: "POST", url: url.absoluteString)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid HTTP response for OAuth token \(isRefresh ? "refresh" : "exchange")")
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            logger.logNetworkError(method: "POST", url: url.absoluteString, error: APIError.serverError(httpResponse.statusCode))
            throw APIError.serverError(httpResponse.statusCode)
        }

        logger.logNetworkRequest(method: "POST", url: url.absoluteString, statusCode: httpResponse.statusCode)
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseDto.self, from: data)
        logger.info("Successfully \(isRefresh ? "refreshed" : "exchanged") OAuth token")
        return tokenResponse
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
    case serverErrorWithMessage(statusCode: Int, message: String)
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode):
            return "Server error: HTTP \(statusCode)"
        case .serverErrorWithMessage(_, let message):
            return message
        }
    }
}
