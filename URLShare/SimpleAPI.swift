import Foundation

class SimpleAPI {
    private static let logger = Logger.network

    // MARK: - Server Info

    static func checkServerReachability() async -> Bool {
        guard let endpoint = KeychainHelper.shared.loadEndpoint(),
              !endpoint.isEmpty,
              let url = URL(string: "\(endpoint)/api/info") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.timeoutInterval = 5.0

        if let token = KeychainHelper.shared.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               200...299 ~= httpResponse.statusCode {
                logger.info("Server is reachable")
                return true
            }
        } catch {
            logger.error("Server reachability check failed: \(error.localizedDescription)")
            return false
        }

        return false
    }

    // MARK: - API Methods
    static func addBookmark(title: String, url: String, labels: [String]? = nil, showStatus: @escaping (String, Bool) -> Void) async {
        logger.info("Adding bookmark: \(url)")
        guard let token = KeychainHelper.shared.loadToken() else {
            showStatus("No token found. Please log in via the main app.", true)
            return
        }
        guard let endpoint = KeychainHelper.shared.loadEndpoint(), !endpoint.isEmpty else {
            showStatus("No server endpoint found.", true)
            return
        }
        let requestDto = CreateBookmarkRequestDto(url: url, title: title, labels: labels)
        guard let requestData = try? JSONEncoder().encode(requestDto) else {
            showStatus("Failed to encode request.", true)
            return
        }
        guard let apiUrl = URL(string: endpoint + "/api/bookmarks") else {
            showStatus("Invalid server endpoint.", true)
            return
        }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestData
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid server response for bookmark creation")
                showStatus("Invalid server response.", true)
                return
            }
            
            logger.logNetworkRequest(method: "POST", url: "/api/bookmarks", statusCode: httpResponse.statusCode)
            
            guard 200...299 ~= httpResponse.statusCode else {
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)
                    }
                }
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("Server error \(httpResponse.statusCode): \(msg)")
                showStatus("Server error: \(httpResponse.statusCode)\n\(msg)", true)
                return
            }
            
            if let resp = try? JSONDecoder().decode(CreateBookmarkResponseDto.self, from: data) {
                logger.info("Bookmark created successfully: \(resp.message)")
                showStatus("Saved: \(resp.message)", false)
            } else {
                logger.info("Bookmark created successfully")
                showStatus("Bookmark saved!", false)
            }
        } catch {
            logger.logNetworkError(method: "POST", url: "/api/bookmarks", error: error)
            showStatus("Network error: \(error.localizedDescription)", true)
        }
    }
    
    static func getBookmarkLabels(showStatus: @escaping (String, Bool) -> Void) async -> [BookmarkLabelDto]? {
        logger.info("Fetching bookmark labels")
        guard let token = KeychainHelper.shared.loadToken() else {
            showStatus("No token found. Please log in via the main app.", true)
            return nil
        }
        guard let endpoint = KeychainHelper.shared.loadEndpoint(), !endpoint.isEmpty else {
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
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
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
