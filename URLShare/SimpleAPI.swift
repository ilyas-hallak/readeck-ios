import Foundation

/// Bündelt die äußeren Abhängigkeiten von `SimpleAPI`, damit die statischen
/// Methoden testbar bleiben, ohne alle Aufrufer in der Extension anzufassen.
struct SimpleAPIEnvironment {
    var session: HTTPSession
    var loadToken: () -> String?
    var loadEndpoint: () -> String?

    static func live() -> Self {
        Self(
            session: HTTPSessionFactory.makeDefault(),
            loadToken: { KeychainHelper.shared.loadToken() },
            loadEndpoint: { KeychainHelper.shared.loadEndpoint() }
        )
    }
}

final class SimpleAPI {
    private static let logger = Logger.network

    /// In Tests überschreibbar; im App-Betrieb bleibt es bei `live()`.
    static var environment = SimpleAPIEnvironment.live()

    // MARK: - Token Management

    private static func getValidToken() async -> String? {
        let authMethod = KeychainHelper.shared.loadAuthMethod()

        if authMethod == .oauth {
            // OAuth authentication - check and refresh if needed
            guard var oauthToken = KeychainHelper.shared.loadOAuthToken() else {
                logger.warning("OAuth token not found")
                return nil
            }

            // Check if token is expired or expiring soon (within 5 minutes)
            if oauthToken.isExpired || willExpireSoon(oauthToken) {
                logger.info("OAuth token expired or expiring soon, attempting refresh")
                if let refreshedToken = await refreshOAuthToken() {
                    return refreshedToken.accessToken
                }
                logger.warning("Failed to refresh OAuth token")
                return oauthToken.accessToken
            }
            return oauthToken.accessToken
        }
        // Classic API token authentication
        return environment.loadToken()
    }

    private static func willExpireSoon(_ token: OAuthToken) -> Bool {
        guard let expiresIn = token.expiresIn else { return false }
        let expiryDate = token.createdAt.addingTimeInterval(TimeInterval(expiresIn))
        let fiveMinutesFromNow = Date().addingTimeInterval(5 * 60)
        return expiryDate < fiveMinutesFromNow
    }

    private static func refreshOAuthToken() async -> OAuthToken? {
        guard let oauthToken = KeychainHelper.shared.loadOAuthToken(),
              let refreshToken = oauthToken.refreshToken,
              let endpoint = environment.loadEndpoint(),
              let clientId = KeychainHelper.shared.loadOAuthClientId() else {
            logger.error("Missing required data for OAuth token refresh")
            return nil
        }

        logger.info("Refreshing OAuth token in Share Extension")

        do {
            let url = URL(string: "\(endpoint)/api/oauth/token")!
            var formData: [String: String] = [
                "grant_type": "refresh_token",
                "client_id": clientId,
                "refresh_token": refreshToken
            ]

            let formBody = formData.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                .joined(separator: "&")

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.httpBody = formBody.data(using: .utf8)

            let (data, response) = try await environment.session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                logger.error("Failed to refresh OAuth token: HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nil
            }

            let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseDto.self, from: data)
            let newToken = OAuthToken(from: tokenResponse)

            // Save new token
            KeychainHelper.shared.saveOAuthToken(newToken)
            logger.info("Successfully refreshed OAuth token in Share Extension")
            return newToken
        } catch {
            logger.error("Error refreshing OAuth token: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Server Info

    static func checkServerReachability() async -> ServerInfoDto? {
        guard let endpoint = environment.loadEndpoint(),
              !endpoint.isEmpty,
              let url = URL(string: "\(endpoint)/api/info") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 5.0

        if let token = await getValidToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }

        HTTPHeadersHelper.shared.applyCustomHeaders(to: &request)

        do {
            let (data, response) = try await environment.session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               200...299 ~= httpResponse.statusCode {
                logger.info("Server is reachable")
                return try? JSONDecoder().decode(ServerInfoDto.self, from: data)
            }
        } catch {
            logger.error("Server reachability check failed: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - API Methods
    // The `showStatus` closure reports (message, isError, savedBookmarkId). The id is
    // read from the `Bookmark-Id` response header on success and is nil on failure —
    // it lets the extension offer an "Open in Readeck" deep link.
    // swiftlint:disable:next discouraged_optional_collection
    static func addBookmark(title: String, url: String, labels: [String]? = nil, html: String? = nil, showStatus: @escaping (String, Bool, String?) -> Void) async {
        logger.info("Adding bookmark: \(url)")
        guard let token = await getValidToken() else {
            showStatus("No token found. Please log in via the main app.", true, nil)
            return
        }
        guard let endpoint = environment.loadEndpoint(), !endpoint.isEmpty else {
            showStatus("No server endpoint found.", true, nil)
            return
        }
        let requestDto = CreateBookmarkRequestDto(url: url, title: title, labels: labels, html: html)
        guard let requestData = try? JSONEncoder().encode(requestDto) else {
            showStatus("Failed to encode request.", true, nil)
            return
        }
        guard let apiUrl = URL(string: endpoint + "/api/bookmarks") else {
            showStatus("Invalid server endpoint.", true, nil)
            return
        }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        HTTPHeadersHelper.shared.applyCustomHeaders(to: &request)
        request.httpBody = requestData
        do {
            let (data, response) = try await environment.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid server response for bookmark creation")
                showStatus("Invalid server response.", true, nil)
                return
            }

            logger.logNetworkRequest(method: "POST", url: "/api/bookmarks", statusCode: httpResponse.statusCode)

            guard 200...299 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)
                    }
                    logger.error("Authentication failed: 401 Unauthorized")
                    showStatus("Session expired. Please log in via the Readeck app.", true, nil)
                    return
                }
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("Server error \(httpResponse.statusCode): \(msg)")
                showStatus("Server error: \(httpResponse.statusCode)\n\(msg)", true, nil)
                return
            }

            let bookmarkId = extractBookmarkId(from: httpResponse)
            if let resp = try? JSONDecoder().decode(CreateBookmarkResponseDto.self, from: data) {
                logger.info("Bookmark created successfully: \(resp.message), id: \(bookmarkId ?? "unknown")")
                showStatus("Saved: \(resp.message)", false, bookmarkId)
            } else {
                logger.info("Bookmark created successfully, id: \(bookmarkId ?? "unknown")")
                showStatus("Bookmark saved!", false, bookmarkId)
            }
        } catch {
            logger.logNetworkError(method: "POST", url: "/api/bookmarks", error: error)
            showStatus("Network error: \(error.localizedDescription)", true, nil)
        }
    }

    /// Reads the created bookmark's id from the response. Readeck returns it in the
    /// `Bookmark-Id` header on `POST /bookmarks`; as a fallback we take the last path
    /// component of the `Location` header (`/api/bookmarks/{id}`).
    private static func extractBookmarkId(from response: HTTPURLResponse) -> String? {
        if let id = response.value(forHTTPHeaderField: "Bookmark-Id"), !id.isEmpty {
            return id
        }
        if let location = response.value(forHTTPHeaderField: "Location"),
           let last = location.split(separator: "/").last.map(String.init),
           !last.isEmpty {
            return last
        }
        return nil
    }

    // swiftlint:disable:next discouraged_optional_collection
    static func getBookmarkLabels(showStatus: @escaping (String, Bool) -> Void) async -> [BookmarkLabelDto]? {
        logger.info("Fetching bookmark labels")
        guard let token = await getValidToken() else {
            showStatus("No token found. Please log in via the main app.", true)
            return nil
        }
        guard let endpoint = environment.loadEndpoint(), !endpoint.isEmpty else {
            showStatus("No server endpoint found.", true)
            return nil
        }
        guard let apiUrl = URL(string: endpoint + "/api/bookmarks/labels") else {
            showStatus("Invalid server endpoint.", true)
            return nil
        }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        HTTPHeadersHelper.shared.applyCustomHeaders(to: &request)
        do {
            let (data, response) = try await environment.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid server response for labels request")
                showStatus("Invalid server response.", true)
                return nil
            }

            logger.logNetworkRequest(method: "GET", url: "/api/bookmarks/labels", statusCode: httpResponse.statusCode)

            guard 200...299 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)
                    }
                    logger.error("Authentication failed: 401 Unauthorized")
                    showStatus("Session expired. Please log in via the Readeck app.", true)
                    return nil
                }
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("Server error \(httpResponse.statusCode): \(msg)")
                showStatus("Server error: \(httpResponse.statusCode)\n\(msg)", true)
                return nil
            }

            let labels = try JSONDecoder().decode([BookmarkLabelDto].self, from: data)
            logger.info("Successfully fetched \(labels.count) bookmark labels")
            return labels
        } catch {
            logger.logNetworkError(method: "GET", url: "/api/bookmarks/labels", error: error)
            showStatus("Network error: \(error.localizedDescription)", true)
            return nil
        }
    }
}
